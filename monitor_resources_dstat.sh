#!/bin/bash

# Script de monitoreo de recursos usando dstat y herramientas del sistema
set -euo pipefail

# Variables de configuración
MONITOR_INTERVAL=${MONITOR_INTERVAL:-1}
CSV_FILE="metrics.csv"
PID_FILE="monitor.pid"

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
print_help() {
    echo -e "${BLUE}Monitor de Recursos con dstat - Pruebas de Estrés${NC}"
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -i, --interval SECS    Intervalo entre muestras (default: 1s)"
    echo "  -f, --file FILE        Archivo CSV de salida (default: metrics.csv)"
    echo "  -s, --stop             Detener monitoreo activo"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo "Herramientas usadas: dstat, vmstat, go tool pprof"
}

# Función para verificar dependencias
check_dependencies() {
    if ! command -v dstat >/dev/null 2>&1; then
        echo -e "${RED}Error: dstat no está instalado${NC}"
        echo -e "Instálalo con: brew install dstat (macOS) o sudo apt-get install dstat (Linux)"
        exit 1
    fi
    
    if ! command -v vmstat >/dev/null 2>&1; then
        echo -e "${YELLOW}Advertencia: vmstat no encontrado, algunas métricas no estarán disponibles${NC}"
    fi
}

# Función para obtener métricas usando dstat
get_dstat_metrics() {
    # Ejecutar dstat en segundo plano y capturar salida
    dstat --time --cpu --mem --disk --net --load --output /tmp/dstat_output.csv $MONITOR_INTERVAL 1 >/dev/null 2>&1 &
    dstat_pid=$!
    sleep $((MONITOR_INTERVAL + 1))
    
    # Leer última línea de salida
    if [ -f "/tmp/dstat_output.csv" ]; then
        last_line=$(tail -n 1 "/tmp/dstat_output.csv")
        
        # Parsear campos de dstat
        # timestamp,usr,sys,idl,wai,hiq,siq,mem_used,mem_buff,mem_cache,mem_free,dsk_read,dsk_writ,net_recv,net_send,load_fifteen
        cpu_usage=$(echo "$last_line" | cut -d',' -f2 | awk '{print $1}')
        mem_used=$(echo "$last_line" | cut -d',' -f8 | awk '{print $1}')
        disk_read=$(echo "$last_line" | cut -d',' -f11 | awk '{print $1}')
        disk_write=$(echo "$last_line" | cut -d',' -f12 | awk '{print $1}')
        net_recv=$(echo "$last_line" | cut -d',' -f13 | awk '{print $1}')
        net_send=$(echo "$last_line" | cut -d',' -f14 | awk '{print $1}')
        load_fifteen=$(echo "$last_line" | cut -d',' -f15 | awk '{print $1}')
        
        # Limpiar proceso dstat
        kill $dstat_pid 2>/dev/null || true
        wait $dstat_pid 2>/dev/null || true
        
        echo "$cpu_usage,$mem_used,$disk_read,$disk_write,$net_recv,$net_send,$load_fifteen"
    else
        echo "N/A,N/A,N/A,N/A,N/A,N/A,N/A"
    fi
}

# Función para obtener métricas específicas de Go
get_go_metrics() {
    # Verificar si hay procesos Go activos
    go_pids=$(pgrep -f "tap_stress" || true)
    
    if [ -n "$go_pids" ]; then
        # Obtener estadísticas de Go usando pprof
        if command -v go >/dev/null 2>&1; then
            # Intentar conectarse a pprof si está disponible
            if curl -s http://localhost:6060/debug/pprof/goroutine?debug=1 >/dev/null 2>&1; then
                go_goroutines=$(curl -s http://localhost:6060/debug/pprof/goroutine?debug=1 | grep -A 1 "goroutine" | tail -n 1 | awk '{print $1}')
                go_heap=$(curl -s http://localhost:6060/debug/pprof/heap?debug=1 | grep -A 1 "alloc" | tail -n 1 | awk '{print $1}')
                go_gc=$(curl -s http://localhost:6060/debug/pprof/trace?seconds=1 | grep -c "GC")
                
                if [ -z "$go_goroutines" ]; then
                    go_goroutines="N/A"
                fi
                if [ -z "$go_heap" ]; then
                    go_heap="N/A"
                fi
                if [ -z "$go_gc" ]; then
                    go_gc="N/A"
                fi
            else
                # Si no hay pprof, estimar basado en procesos
                go_goroutines=$(ps -o pid= -C tap_stress 2>/dev/null | wc -l)
                go_heap=$(ps -o rss= -C tap_stress 2>/dev/null | awk '{sum+=$1} END {print sum/1024}')
                go_gc="N/A"
            fi
        else
            go_goroutines="N/A"
            go_heap="N/A"
            go_gc="N/A"
        fi
    else
        go_goroutines="N/A"
        go_heap="N/A"
        go_gc="N/A"
    fi
    
    echo "$go_goroutines,$go_heap,$go_gc"
}

# Función para verificar umbrales
check_thresholds() {
    local cpu=$1
    local memory=$2
    local disk_read=$3
    local disk_write=$4
    local net_recv=$5
    local net_send=$6
    local load=$7
    local go_goroutines=$8
    local go_heap=$9
    local go_gc=${10}
    
    local alerts=()
    
    if [ "$cpu" != "N/A" ] && [ $(echo "$cpu > 80" | bc -l) -eq 1 ]; then
        alerts+=("CPU: ${cpu}% (umbral: 80%)")
    fi
    
    if [ "$memory" != "N/A" ] && [ $(echo "$memory > 512" | bc -l) -eq 1 ]; then
        alerts+=("Memoria: ${memory}MB (umbral: 512MB)")
    fi
    
    if [ "$disk_read" != "N/A" ] && [ $(echo "$disk_read > 100" | bc -l) -eq 1 ]; then
        alerts+=("Disco lectura: ${disk_read}MB/s (umbral: 100MB/s)")
    fi
    
    if [ "$disk_write" != "N/A" ] && [ $(echo "$disk_write > 100" | bc -l) -eq 1 ]; then
        alerts+=("Disco escritura: ${disk_write}MB/s (umbral: 100MB/s)")
    fi
    
    if [ "$net_recv" != "N/A" ] && [ $(echo "$net_recv > 100" | bc -l) -eq 1 ]; then
        alerts+=("Red recepción: ${net_recv}MB/s (umbral: 100MB/s)")
    fi
    
    if [ "$net_send" != "N/A" ] && [ $(echo "$net_send > 100" | bc -l) -eq 1 ]; then
        alerts+=("Red envío: ${net_send}MB/s (umbral: 100MB/s)")
    fi
    
    if [ "$load" != "N/A" ] && [ $(echo "$load > 2" | bc -l) -eq 1 ]; then
        alerts+=("Carga del sistema: ${load} (umbral: 2)")
    fi
    
    if [ "$go_goroutines" != "N/A" ] && [ $go_goroutines -gt 1000 ]; then
        alerts+=("Go goroutines: ${go_goroutines} (umbral: 1000)")
    fi
    
    if [ "$go_heap" != "N/A" ] && [ $(echo "$go_heap > 512" | bc -l) -eq 1 ]; then
        alerts+=("Go heap: ${go_heap}MB (umbral: 512MB)")
    fi
    
    if [ "$go_gc" != "N/A" ] && [ $go_gc -gt 100 ]; then
        alerts+=("Go GC pauses: ${go_gc} (umbral: 100)")
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

# Función para iniciar monitoreo
start_monitoring() {
    echo -e "${BLUE}=== Iniciando monitoreo con dstat ===${NC}"
    echo -e "Intervalo: ${MONITOR_INTERVAL}s | Archivo: $CSV_FILE"
    
    # Crear archivo CSV con encabezados
    echo "timestamp,cpu_usage,mem_used,disk_read,disk_write,net_recv,net_send,load_fifteen,go_goroutines,go_heap,go_gc" > "$CSV_FILE"
    
    # Guardar PID
    echo $$ > "$PID_FILE"
    
    # Iniciar bucle de monitoreo
    while true; do
        # Obtener timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Obtener métricas del sistema
        read -r sys_metrics <<< "$(get_dstat_metrics)"
        cpu_usage=$(echo "$sys_metrics" | cut -d',' -f1)
        mem_used=$(echo "$sys_metrics" | cut -d',' -f2)
        disk_read=$(echo "$sys_metrics" | cut -d',' -f3)
        disk_write=$(echo "$sys_metrics" | cut -d',' -f4)
        net_recv=$(echo "$sys_metrics" | cut -d',' -f5)
        net_send=$(echo "$sys_metrics" | cut -d',' -f6)
        load_fifteen=$(echo "$sys_metrics" | cut -d',' -f7)
        
        # Obtener métricas de Go
        read -r go_metrics <<< "$(get_go_metrics)"
        go_goroutines=$(echo "$go_metrics" | cut -d',' -f1)
        go_heap=$(echo "$go_metrics" | cut -d',' -f2)
        go_gc=$(echo "$go_metrics" | cut -d',' -f3)
        
        # Verificar umbrales
        check_thresholds "$cpu_usage" "$mem_used" "$disk_read" "$disk_write" "$net_recv" "$net_send" "$load_fifteen" "$go_goroutines" "$go_heap" "$go_gc"
        
        # Escribir en CSV
        echo "$timestamp,$cpu_usage,$mem_used,$disk_read,$disk_write,$net_recv,$net_send,$load_fifteen,$go_goroutines,$go_heap,$go_gc" >> "$CSV_FILE"
        
        # Esperar siguiente intervalo
        sleep "$MONITOR_INTERVAL"
    done
}

# Función para detener monitoreo
stop_monitoring() {
    if [ -f "$PID_FILE" ]; then
        monitor_pid=$(cat "$PID_FILE")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            echo -e "${YELLOW}Deteniendo monitoreo (PID: $monitor_pid)...${NC}"
            kill "$monitor_pid" 2>/dev/null || true
            rm -f "$PID_FILE"
            echo -e "${GREEN}Monitoreo detenido${NC}"
        else
            echo -e "${YELLOW}No se encontró proceso de monitoreo activo${NC}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${YELLOW}No hay monitoreo activo${NC}"
    fi
}

# Función para mostrar estado actual
status_monitoring() {
    if [ -f "$PID_FILE" ]; then
        monitor_pid=$(cat "$PID_FILE")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            echo -e "${GREEN}Monitoreo activo (PID: $monitor_pid)${NC}"
            echo -e "Archivo: $CSV_FILE"
            echo -e "Intervalo: ${MONITOR_INTERVAL}s"
            return 0
        fi
    fi
    
    echo -e "${RED}Monitoreo inactivo${NC}"
    return 1
}

# Función principal
main() {
    # Verificar dependencias
    check_dependencies
    
    # Parámetros por línea de comandos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -f|--file)
                CSV_FILE="$2"
                shift 2
                ;;
            -s|--stop)
                stop_monitoring
                exit 0
                ;;
            -p|--status)
                status_monitoring
                exit 0
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
    
    # Verificar si ya hay un monitoreo activo
    if status_monitoring >/dev/null 2>&1; then
        echo -e "${YELLOW}Ya hay un monitoreo activo. Detélolo primero con -s${NC}"
        exit 1
    fi
    
    # Iniciar monitoreo
    start_monitoring
}

# Ejecutar main
main "$@"