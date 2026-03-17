#!/bin/bash

# Plan de Pruebas de Estrés para 1 Millón de Taps
# Script Principal: Orquesta todas las etapas de prueba

set -euo pipefail

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
CONFIG_FILE="config.yaml"
DEFAULT_MAX_TAPS=1000000
DEFAULT_DURATION=3600
DEFAULT_INTERVAL=1
INTERVAL=1

# Función para mostrar ayuda
print_help() {
    echo -e "${BLUE}Plan de Pruebas de Estrés - Tap Support${NC}"
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -c, --config FILE    Archivo de configuración (default: config.yaml)"
    echo "  -m, --max-taps N     Máximo número de taps (default: 1000000)"
    echo "  -d, --duration SECS  Duración de la prueba en segundos (default: 3600)"
    echo "  -i, --interval SECS  Intervalo entre etapas (default: 1)"
    echo "  -h, --help           Mostrar esta ayuda"
    echo "  -v, --verbose        Modo detallado"
    echo ""
    echo "Etapas del plan de pruebas:"
    echo "  1. Carga Normal (10% de capacidad)"
    echo "  2. Carga Moderada (50% de capacidad)"
    echo "  3. Carga Máxima (100% de capacidad)"
    echo "  4. Carga Sostenida (100% con picos)"
}

# Función para cargar configuración
load_config() {
    # Solo cargar configuración del archivo si no se especificaron por línea de comandos
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Cargando configuración desde $CONFIG_FILE${NC}"
        
        # Cargar valores del archivo solo si no se establecieron previamente
        if [ -z "${MAX_TAPS_LOADED+x}" ]; then
            MAX_TAPS=$(yq eval '.stress_test.max_taps' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_MAX_TAPS")
        fi
        if [ -z "${DURATION_LOADED+x}" ]; then
            DURATION=$(yq eval '.stress_test.duration' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_DURATION")
        fi
        if [ -z "${INTERVAL_LOADED+x}" ]; then
            INTERVAL=$(yq eval '.stress_test.interval' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_INTERVAL")
        fi
        if [ -z "${VERBOSE_LOADED+x}" ]; then
            VERBOSE=$(yq eval '.stress_test.verbose' "$CONFIG_FILE" 2>/dev/null || echo "false")
        fi
        
        # Umbrales siempre se cargan del archivo o valores por defecto
        CPU_THRESHOLD=$(yq eval '.stress_test.thresholds.cpu' "$CONFIG_FILE" 2>/dev/null || echo "80")
        MEMORY_THRESHOLD=$(yq eval '.stress_test.thresholds.memory' "$CONFIG_FILE" 2>/dev/null || echo "85")
        DISK_THRESHOLD=$(yq eval '.stress_test.thresholds.disk' "$CONFIG_FILE" 2>/dev/null || echo "1000")
        NETWORK_THRESHOLD=$(yq eval '.stress_test.thresholds.network' "$CONFIG_FILE" 2>/dev/null || echo "100")
    else
        echo -e "${YELLOW}No se encontró $CONFIG_FILE, usando valores por defecto${NC}"
        if [ -z "${MAX_TAPS_LOADED+x}" ]; then
            MAX_TAPS=$DEFAULT_MAX_TAPS
        fi
        if [ -z "${DURATION_LOADED+x}" ]; then
            DURATION=$DEFAULT_DURATION
        fi
        if [ -z "${INTERVAL_LOADED+x}" ]; then
            INTERVAL=$DEFAULT_INTERVAL
        fi
        if [ -z "${VERBOSE_LOADED+x}" ]; then
            VERBOSE=false
        fi
        CPU_THRESHOLD=80
        MEMORY_THRESHOLD=85
        DISK_THRESHOLD=1000
        NETWORK_THRESHOLD=100
    fi
}

# Función para mostrar progreso
show_progress() {
    local current=$1
    local total=$2
    local percent=$(( (current * 100) / total ))
    local bar=""
    for i in $(seq 1 50); do
        if [ $i -le $((percent / 2)) ]; then
            bar="#"
        else
            bar="."
        fi
        echo -n "$bar"
    done
    echo -e " ${percent}% (${current}/${total})"
}

# Función para iniciar monitoreo (solo la primera vez)
start_monitoring() {
    if [ -z "${MONITOR_STARTED+x}" ]; then
        echo -e "${BLUE}Iniciando monitoreo de métricas...${NC}"
        ./monitor_resources.sh > metrics.log 2>&1 &
        MONITOR_PID=$!
        MONITOR_STARTED=true
        sleep 2
    fi
}

# Función para detener monitoreo
stop_monitoring() {
    if [ -n "${MONITOR_PID+set}" ] && [ -n "${MONITOR_STARTED+x}" ]; then
        echo -e "${BLUE}Deteniendo monitoreo...${NC}"
        kill $MONITOR_PID 2>/dev/null || true
        wait $MONITOR_PID 2>/dev/null || true
        unset MONITOR_STARTED
    fi
}

# Función para verificar umbrales
check_thresholds() {
    local cpu=$1
    local memory=$2
    local disk=$3
    local network=$4
    
    local alerts=()
    
    # Verificar CPU
    if [ "$cpu" != "N/A" ] && [ -n "$cpu" ] && [ "$cpu" -gt "$CPU_THRESHOLD" ] 2>/dev/null; then
        alerts+=("CPU: ${cpu}% (umbral: ${CPU_THRESHOLD}%)")
    fi
    
    # Verificar Memoria
    if [ "$memory" != "N/A" ] && [ -n "$memory" ] && [ "$memory" -gt "$MEMORY_THRESHOLD" ] 2>/dev/null; then
        alerts+=("Memoria: ${memory}% (umbral: ${MEMORY_THRESHOLD}%)")
    fi
    
    # Verificar Disco (IOPS)
    if [ "$disk" != "N/A" ] && [ -n "$disk" ] && [ "$disk" -gt "$DISK_THRESHOLD" ] 2>/dev/null; then
        alerts+=("Disco: ${disk} IOPS (umbral: ${DISK_THRESHOLD} IOPS)")
    fi
    
    # Verificar Red (MB/s)
    if [ "$network" != "N/A" ] && [ -n "$network" ] && [ "$(echo "$network > $NETWORK_THRESHOLD" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null; then
        alerts+=("Red: ${network} MB/s (umbral: ${NETWORK_THRESHOLD} MB/s)")
    fi
    
    if [ ${#alerts[@]} -gt 0 ]; then
        echo -e "${RED}ALERTA: Se superaron umbrales:${NC}"
        for alert in "${alerts[@]}"; do
            echo -e "  ${RED}⚠️  $alert${NC}"
        done
        return 1
    fi
    
    return 0
}

# Etapa 1: Carga Normal
stage_normal() {
    local max_taps=$((MAX_TAPS / 10))
    local duration=$((DURATION / 4))
    
    echo -e "\n${GREEN}=== Etapa 1: Carga Normal (${max_taps} taps, ${duration}s) ===${NC}"
    echo -e "${BLUE}Simulando patrones de uso normal...${NC}"
    
    start_monitoring
    
    ./tap_stress -taps $max_taps -duration $duration -pattern normal > stage1.log 2>&1 &
    STRESS_PID=$!
    
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
        
        # Obtener métricas actuales
        if [ -f "metrics.csv" ]; then
            local last_line=$(tail -n 1 metrics.csv)
            local cpu=$(echo "$last_line" | cut -d',' -f2)
            local memory=$(echo "$last_line" | cut -d',' -f5)
            local disk=$(echo "$last_line" | cut -d',' -f6)
            local network=$(echo "$last_line" | cut -d',' -f8)
            
            check_thresholds $cpu $memory $disk $network
            
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}Progreso: ${elapsed}s/${duration}s | CPU: ${cpu}% | Mem: ${memory}% | Disco: ${disk}% | Red: ${network} req/s${NC}"
            fi
        fi
    done
    
    kill $STRESS_PID 2>/dev/null || true
    wait $STRESS_PID 2>/dev/null || true
    
    echo -e "${GREEN}Etapa 1 completada${NC}"
}

# Etapa 2: Carga Moderada
stage_moderate() {
    local max_taps=$((MAX_TAPS / 2))
    local duration=$((DURATION / 4))
    
    echo -e "\n${GREEN}=== Etapa 2: Carga Moderada (${max_taps} taps, ${duration}s) ===${NC}"
    echo -e "${BLUE}Simulando carga de trabajo moderada...${NC}"
    
    start_monitoring
    
    ./tap_stress -taps $max_taps -duration $duration -pattern moderate > stage2.log 2>&1 &
    STRESS_PID=$!
    
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
        
        if [ -f "metrics.csv" ]; then
            local last_line=$(tail -n 1 metrics.csv)
            local cpu=$(echo "$last_line" | cut -d',' -f2)
            local memory=$(echo "$last_line" | cut -d',' -f5)
            local disk=$(echo "$last_line" | cut -d',' -f6)
            local network=$(echo "$last_line" | cut -d',' -f8)
            
            check_thresholds $cpu $memory $disk $network
            
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}Progreso: ${elapsed}s/${duration}s | CPU: ${cpu}% | Mem: ${memory}% | Disco: ${disk} IOPS | Red: ${network} MB/s${NC}"
            fi
        fi
    done
    
    kill $STRESS_PID 2>/dev/null || true
    wait $STRESS_PID 2>/dev/null || true
    
    echo -e "${GREEN}Etapa 2 completada${NC}"
}

# Etapa 3: Carga Máxima
stage_maximum() {
    local max_taps=$MAX_TAPS
    local duration=$((DURATION / 4))
    
    echo -e "\n${GREEN}=== Etapa 3: Carga Máxima (${max_taps} taps, ${duration}s) ===${NC}"
    echo -e "${BLUE}Simulando carga máxima del sistema...${NC}"
    
    start_monitoring
    
    ./tap_stress -taps $max_taps -duration $duration -pattern maximum > stage3.log 2>&1 &
    STRESS_PID=$!
    
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
        
        if [ -f "metrics.csv" ]; then
            local last_line=$(tail -n 1 metrics.csv)
            local cpu=$(echo "$last_line" | cut -d',' -f2)
            local memory=$(echo "$last_line" | cut -d',' -f5)
            local disk=$(echo "$last_line" | cut -d',' -f6)
            local network=$(echo "$last_line" | cut -d',' -f8)
            
            check_thresholds $cpu $memory $disk $network
            
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}Progreso: ${elapsed}s/${duration}s | CPU: ${cpu}% | Mem: ${memory}% | Disco: ${disk} IOPS | Red: ${network} MB/s${NC}"
            fi
        fi
    done
    
    kill $STRESS_PID 2>/dev/null || true
    wait $STRESS_PID 2>/dev/null || true
    
    echo -e "${GREEN}Etapa 3 completada${NC}"
}

# Etapa 4: Carga Sostenida
stage_sustained() {
    local max_taps=$MAX_TAPS
    local duration=$((DURATION / 4))
    
    echo -e "\n${GREEN}=== Etapa 4: Carga Sostenida (${max_taps} taps, ${duration}s) ===${NC}"
    echo -e "${BLUE}Simulando carga sostenida con picos...${NC}"
    
    start_monitoring
    
    ./tap_stress -taps $max_taps -duration $duration -pattern sustained > stage4.log 2>&1 &
    STRESS_PID=$!
    
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
        
        if [ -f "metrics.csv" ]; then
            local last_line=$(tail -n 1 metrics.csv)
            local cpu=$(echo "$last_line" | cut -d',' -f2)
            local memory=$(echo "$last_line" | cut -d',' -f5)
            local disk=$(echo "$last_line" | cut -d',' -f6)
            local network=$(echo "$last_line" | cut -d',' -f8)
            
            check_thresholds $cpu $memory $disk $network
            
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}Progreso: ${elapsed}s/${duration}s | CPU: ${cpu}% | Mem: ${memory}% | Disco: ${disk} IOPS | Red: ${network} MB/s${NC}"
            fi
        fi
    done
    
    kill $STRESS_PID 2>/dev/null || true
    wait $STRESS_PID 2>/dev/null || true
    
    echo -e "${GREEN}Etapa 4 completada${NC}"
}

# Función para generar informe
generate_report() {
    echo -e "\n${GREEN}=== Generando informe de resultados ===${NC}"
    
    # Crear directorio de resultados
    mkdir -p results
    
    # Procesar métricas
    if [ -f "metrics.csv" ]; then
        python3 analyze_results.py metrics.csv results/metrics_analysis.csv
        echo -e "${GREEN}Análisis de métricas completado${NC}"
    fi
    
    # Procesar logs de etapas
    for i in 1 2 3 4; do
        if [ -f "stage${i}.log" ]; then
            local success=$(grep -c "SUCCESS" "stage${i}.log" || true)
            local errors=$(grep -c "ERROR" "stage${i}.log" || true)
            echo "Etapa $i: $success éxitos, $errors errores" >> results/stage_summary.txt
        fi
    done
    
    # Crear resumen
    cat > results/summary.txt << EOF
Plan de Pruebas de Estrés - Tap Support
========================================

Parámetros:
- Máximo taps: $MAX_TAPS
- Duración total: $DURATION segundos
- Umbrales: CPU ${CPU_THRESHOLD}%, Mem ${MEMORY_THRESHOLD}%, Disco ${DISK_THRESHOLD}%, Red ${NETWORK_THRESHOLD} req/s

Resultados:
$(cat results/stage_summary.txt 2>/dev/null || echo "No hay datos de etapas")

Métricas procesadas: results/metrics_analysis.csv
Logs de etapas: stage1.log, stage2.log, stage3.log, stage4.log
EOF

    echo -e "${GREEN}Informe generado en directorio 'results/'${NC}"
}

# Función principal
main() {
    # Parámetros por línea de comandos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -m|--max-taps)
                MAX_TAPS="$2"
                MAX_TAPS_LOADED=true
                shift 2
                ;;
            -d|--duration)
                DURATION="$2"
                DURATION_LOADED=true
                shift 2
                ;;
            -i|--interval)
                INTERVAL="$2"
                INTERVAL_LOADED=true
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                VERBOSE_LOADED=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}Opción no válida: $1${NC}"
                print_help
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}=== Iniciando Plan de Pruebas de Estrés ===${NC}"
    echo -e "${BLUE}Configuración:${NC}"
    echo -e "  Máximo taps: ${MAX_TAPS}"
    echo -e "  Duración: ${DURATION} segundos"
    echo -e "  Intervalo: ${INTERVAL} segundos"
    echo -e "  Modo detallado: ${VERBOSE:-false}"
    
    # Cargar configuración (solo si no se especificaron por línea de comandos)
    load_config
    
    # Crear directorios
    mkdir -p results logs
    
    # Ejecutar etapas
    stage_normal
    stage_moderate
    stage_maximum
    stage_sustained
    
    # Detener monitoreo
    stop_monitoring
    
    # Generar informe
    generate_report
    
    echo -e "\n${GREEN}=== Plan de pruebas completado ===${NC}"
    echo -e "${GREEN}Resultados disponibles en directorio 'results/'${NC}"
}

# Ejecutar main
main "$@"