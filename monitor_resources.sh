#!/bin/bash

# Script de monitoreo de recursos para pruebas de estres
# Captura métricas del sistema y específicos de Go

set -euo pipefail

# Variables de configuración
MONITOR_INTERVAL=${MONITOR_INTERVAL:-1}
CSV_FILE="metrics.csv"
PID_FILE="monitor.pid"
THRESHOLDS_CONFIG="thresholds.conf"

# Estado para cálculo de tasa de red
PREV_NET_IN=0
PREV_NET_OUT=0
PREV_TIMESTAMP=0

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
print_help() {
    echo -e "${BLUE}Monitor de Recursos para Pruebas de Estrés${NC}"
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -i, --interval SECS    Intervalo entre muestras (default: 1s)"
    echo "  -f, --file FILE        Archivo CSV de salida (default: metrics.csv)"
    echo "  -t, --thresholds FILE  Archivo de configuración de umbrales (default: thresholds.conf)"
    echo "  -s, --stop             Detener monitoreo activo"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo "Métricas capturadas:"
    echo "  - CPU: uso, temperatura, frecuencia"
    echo "  - Memoria: RSS, heap, GC"
    echo "  - Disco: IOPS, latencia"
    echo "  - Red: ancho de banda"
    echo "  - Go específico: goroutines, heap, GC pauses"
}

# Función para cargar umbrales de configuración
load_thresholds() {
    if [ -f "$THRESHOLDS_CONFIG" ]; then
        echo -e "${YELLOW}Cargando umbrales desde $THRESHOLDS_CONFIG${NC}"
        CPU_THRESHOLD=$(grep '^cpu_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "80")
        MEMORY_THRESHOLD=$(grep '^memory_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "85")
        DISK_THRESHOLD=$(grep '^disk_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "90")
        NETWORK_THRESHOLD=$(grep '^network_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "1000")
        GO_GOROUTINES_THRESHOLD=$(grep '^go_goroutines_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "1000")
        GO_HEAP_THRESHOLD=$(grep '^go_heap_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "512")
        GO_GC_THRESHOLD=$(grep '^go_gc_threshold=' "$THRESHOLDS_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "100")
    else
        echo -e "${YELLOW}No se encontró $THRESHOLDS_CONFIG, usando valores por defecto${NC}"
        CPU_THRESHOLD=80
        MEMORY_THRESHOLD=85
        DISK_THRESHOLD=90
        NETWORK_THRESHOLD=1000
        GO_GOROUTINES_THRESHOLD=1000
        GO_HEAP_THRESHOLD=512
        GO_GC_THRESHOLD=100
    fi
}

# Función para obtener métricas del sistema
get_system_metrics() {
    # CPU usage
    cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | cut -d'%' -f1)
    
    # CPU temperature (macOS)
    if command -v istats >/dev/null 2>&1; then
        cpu_temp=$(istats | grep "CPU temp" | awk '{print $3}' | cut -d'.' -f1)
    else
        cpu_temp="N/A"
    fi
    
    # CPU frequency
    if command -v sysctl >/dev/null 2>&1; then
        cpu_freq=$(sysctl -n hw.cpufrequency 2>/dev/null | awk '{print $1/1000000}')
        if [ -z "$cpu_freq" ]; then
            cpu_freq="N/A"
        fi
    else
        cpu_freq="N/A"
    fi
    
    # Memory usage
    if command -v vm_stat >/dev/null 2>&1; then
        mem_total=$(vm_stat | grep "Pages free" | awk '{print $3}' | awk '{printf "%.0f", $1*4096/1024/1024}')
        mem_used=$(vm_stat | grep "Pages active" | awk '{print $3}' | awk '{printf "%.0f", $1*4096/1024/1024}')
        mem_usage=$(echo "scale=2; ($mem_used/($mem_used+$mem_total))*100" | bc)
    else
        mem_usage="N/A"
    fi
    
    # Disk I/O (macOS)
    if command -v iostat >/dev/null 2>&1; then
        disk_iops=$(iostat -d 1 1 | tail -n 1 | awk '{print $2}')
        disk_latency="N/A"  # No disponible con iostat -d
    else
        disk_iops="N/A"
        disk_latency="N/A"
    fi
    
    # Network (macOS) - Calculate rate instead of total bytes
    if command -v netstat >/dev/null 2>&1; then
        current_net_in=$(netstat -i -b | grep "en0" | head -n 1 | awk '{print $7}')
        current_net_out=$(netstat -i -b | grep "en0" | head -n 1 | awk '{print $10}')
        current_time=$(date +%s)
        
        if [ $PREV_TIMESTAMP -gt 0 ]; then
            time_diff=$((current_time - PREV_TIMESTAMP))
            if [ $time_diff -gt 0 ]; then
                # Calculate differences, handling potential counter resets
                if [ $current_net_in -ge $PREV_NET_IN ]; then
                    bytes_in_diff=$((current_net_in - PREV_NET_IN))
                else
                    bytes_in_diff=0
                fi
                
                if [ $current_net_out -ge $PREV_NET_OUT ]; then
                    bytes_out_diff=$((current_net_out - PREV_NET_OUT))
                else
                    bytes_out_diff=0
                fi
                
                total_bytes=$((bytes_in_diff + bytes_out_diff))
                # Convert to MB/s
                network_bandwidth=$(echo "scale=2; $total_bytes / $time_diff / 1024 / 1024" | bc)
            else
                network_bandwidth="0"
            fi
        else
            network_bandwidth="0"
        fi
        
        # Update previous values
        PREV_NET_IN=$current_net_in
        PREV_NET_OUT=$current_net_out
        PREV_TIMESTAMP=$current_time
    else
        network_bandwidth="N/A"
    fi
    
    echo "$cpu_usage,$cpu_temp,$cpu_freq,$mem_usage,$disk_iops,$disk_latency,$network_bandwidth"
}

# Función para obtener métricas específicas de Go
get_go_metrics() {
    # Verificar si hay procesos Go activos
    go_pids=$(pgrep -f "tap_stress" || true)
    
    if [ -n "$go_pids" ]; then
        # Obtener estadísticas de Go usando pprof
        if command -v go >/dev/null 2>&1; then
            # Usar go tool pprof para obtener estadísticas
            # Nota: Esto asume que el proceso Go está compilado con pprof habilitado
            go_goroutines=$(go tool pprof -text http://localhost:6060/debug/pprof/goroutine?debug=1 2>/dev/null | grep -A 1 "goroutine" | tail -n 1 | awk '{print $1}')
            go_heap=$(go tool pprof -text http://localhost:6060/debug/pprof/heap?debug=1 2>/dev/null | grep -A 1 "alloc" | tail -n 1 | awk '{print $1}')
            go_gc=$(go tool pprof -text http://localhost:6060/debug/pprof/trace?seconds=1 2>/dev/null | grep -c "GC")
            
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

# Función para verificar umbrales y generar alertas
check_thresholds() {
    local cpu=$1
    local memory=$2
    local disk=$3
    local network=$4
    local go_goroutines=$5
    local go_heap=$6
    local go_gc=$7
    
    local alerts=()
    
    if [ "$cpu" != "N/A" ] && [ $(echo "$cpu > $CPU_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("CPU: ${cpu}% (umbral: ${CPU_THRESHOLD}%)")
    fi
    
    if [ "$memory" != "N/A" ] && [ $(echo "$memory > $MEMORY_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("Memoria: ${memory}% (umbral: ${MEMORY_THRESHOLD}%)")
    fi
    
    if [ "$disk_iops" != "N/A" ] && [ $(echo "$disk_iops > $DISK_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("Disco: ${disk_iops} IOPS (umbral: ${DISK_THRESHOLD} IOPS)")
    fi
    
    if [ "$network_bandwidth" != "N/A" ] && [ $(echo "$network_bandwidth > $NETWORK_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("Red: ${network_bandwidth} MB/s (umbral: ${NETWORK_THRESHOLD} MB/s)")
    fi
    
    if [ "$go_goroutines" != "N/A" ] && [ $(echo "$go_goroutines > $GO_GOROUTINES_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("Go goroutines: ${go_goroutines} (umbral: ${GO_GOROUTINES_THRESHOLD})")
    fi
    
    if [ "$go_heap" != "N/A" ] && [ $(echo "$go_heap > $GO_HEAP_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("Go heap: ${go_heap}MB (umbral: ${GO_HEAP_THRESHOLD}MB)")
    fi
    
    if [ "$go_gc" != "N/A" ] && [ $(echo "$go_gc > $GO_GC_THRESHOLD" | bc -l) -eq 1 ]; then
        alerts+=("Go GC pauses: ${go_gc} (umbral: ${GO_GC_THRESHOLD})")
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
    echo -e "${BLUE}=== Iniciando monitoreo de recursos ===${NC}"
    echo -e "Intervalo: ${MONITOR_INTERVAL}s | Archivo: $CSV_FILE"
    
    # Crear archivo CSV con encabezados (solo si no existe o está vacío)
    if [ ! -s "$CSV_FILE" ]; then
        echo "Escribiendo encabezado en $CSV_FILE" >&2
        echo "timestamp,cpu_usage,cpu_temp,cpu_freq,mem_usage,disk_iops,disk_latency,network_bandwidth,go_goroutines,go_heap,go_gc" > "$CSV_FILE"
    else
        echo "Archivo $CSV_FILE ya existe y no está vacío" >&2
    fi
    
    # Guardar PID
    echo $$ > "$PID_FILE"
    
    # Iniciar bucle de monitoreo
    while true; do
        # Obtener timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Obtener métricas del sistema
        sys_metrics=$(get_system_metrics)
        read -r sys_metrics <<< "$sys_metrics"
        cpu_usage=$(echo "$sys_metrics" | cut -d',' -f1)
        cpu_temp=$(echo "$sys_metrics" | cut -d',' -f2)
        cpu_freq=$(echo "$sys_metrics" | cut -d',' -f3)
        mem_usage=$(echo "$sys_metrics" | cut -d',' -f4)
        disk_iops=$(echo "$sys_metrics" | cut -d',' -f5)
        disk_latency=$(echo "$sys_metrics" | cut -d',' -f6)
        network_bandwidth=$(echo "$sys_metrics" | cut -d',' -f7)
        
        # Obtener métricas de Go
        go_metrics=$(get_go_metrics)
        read -r go_metrics <<< "$go_metrics"
        go_goroutines=$(echo "$go_metrics" | cut -d',' -f1)
        go_heap=$(echo "$go_metrics" | cut -d',' -f2)
        go_gc=$(echo "$go_metrics" | cut -d',' -f3)
        
        # Verificar umbrales (y capturar cualquier error)
        check_thresholds "$cpu_usage" "$mem_usage" "$disk_iops" "$network_bandwidth" "$go_goroutines" "$go_heap" "$go_gc" 2>&1 || true
        
        # Escribir en CSV
        echo "$timestamp,$cpu_usage,$cpu_temp,$cpu_freq,$mem_usage,$disk_iops,$disk_latency,$network_bandwidth,$go_goroutines,$go_heap,$go_gc" >> "$CSV_FILE"
        
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
            -t|--thresholds)
                THRESHOLDS_CONFIG="$2"
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
    
    # Cargar umbrales
    load_thresholds
    
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