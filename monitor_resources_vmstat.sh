#!/bin/bash

# Script de monitoreo de recursos usando vmstat y herramientas del sistema
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
    echo -e "${BLUE}Monitor de Recursos con vmstat - Pruebas de Estrés${NC}"
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -i, --interval SECS    Intervalo entre muestras (default: 1s)"
    echo "  -f, --file FILE        Archivo CSV de salida (default: metrics.csv)"
    echo "  -s, --stop             Detener monitoreo activo"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo "Herramientas usadas: vmstat, iostat, netstat, go tool pprof"
}

# Función para verificar dependencias
check_dependencies() {
    if ! command -v vmstat >/dev/null 2>&1; then
        echo -e "${RED}Error: vmstat no está instalado${NC}"
        echo -e "Instálalo con: brew install vmstat (macOS) o sudo apt-get install sysstat (Linux)"
        exit 1
    fi
    
    if ! command -v iostat >/dev/null 2>&1; then
        echo -e "${YELLOW}Advertencia: iostat no encontrado, algunas métricas de disco no estarán disponibles${NC}"
    fi
    
    if ! command -v netstat >/dev/null 2>&1; then
        echo -e "${YELLOW}Advertencia: netstat no encontrado, métricas de red no estarán disponibles${NC}"
    fi
}

# Función para obtener métricas del sistema usando vmstat
get_vmstat_metrics() {
    # Ejecutar vmstat y capturar salida
    vmstat_output=$(vmstat $MONITOR_INTERVAL 1 2>/dev/null | tail -n 1)
    
    if [ -n "$vmstat_output" ]; then
        # Parsear campos de vmstat: r b swpd free buff cache si so bi in cs us sy id wa st
        cpu_us=$(echo "$vmstat_output" | awk '{print $13}')
        cpu_sys=$(echo "$vmstat_output" | awk '{print $14}')
        cpu_idle=$(echo "$vmstat_output" | awk '{print $15}')
        cpu_wait=$(echo "$vmstat_output" | awk '{print $16}')
        mem_free=$(echo "$vmstat_output" | awk '{print $4}')
        mem_swap_in=$(echo "$vmstat_output" | awk '{print $7}')
        mem_swap_out=$(echo "$vmstat_output" | awk '{print $8}')
        
        # Calcular CPU usage total
        cpu_usage=$(echo "scale=2; 100 - $cpu_idle" | bc)
        
        # Convertir memoria a MB
        mem_free_mb=$(echo "scale=2; $mem_free / 1024" | bc)
        
        echo "$cpu_usage,$cpu_us,$cpu_sys,$cpu_idle,$cpu_wait,$mem_free_mb,$mem_swap_in,$mem_swap_out"
    else
        echo "N/A,N/A,N/A,N/A,N/A,N/A,N/A,N/A"
    fi
}

# Función para obtener métricas de disco usando iostat
get_disk_metrics() {
    if command -v iostat >/dev/null 2>&1; then
        # Ejecutar iostat y capturar salida
        iostat_output=$(iostat -d -x $MONITOR_INTERVAL 1 2>/dev/null | tail -n 1)
        
        if [ -n "$iostat_output" ]; then
            # Parsear campos de iostat: device r/s w/s rkB/s wkB/s rrqm/s wrqm/s %rrqm %wrqm %r/%w await r_await w_await svctm %util
            disk_read=$(echo "$iostat_output" | awk '{print $4}')
            disk_write=$(echo "$iostat_output" | awk '{print $5}')
            disk_util=$(echo "$iostat_output" | awk '{print $14}')
            disk_await=$(echo "$iostat_output" | awk '{print $11}')
            
            echo "$disk_read,$disk_write,$disk_util,$disk_await"
        else
            echo "N/A,N/A,N/A,N/A"
        fi
    else
        echo "N/A,N/A,N/A,N/A"
    fi
}

# Función para obtener métricas de red usando netstat
get_network_metrics() {
    if command -v netstat >/dev/null 2>&1; then
        # Ejecutar netstat y capturar salida
        netstat_output=$(netstat -i -b 2>/dev/null | grep "en0" | head -n 1)
        
        if [ -n "$netstat_output" ]; then
            # Parsear campos de netstat: Name Mtu Network Address Ipkts Ierrs Opkts Oerrs Coll
            net_ipkts=$(echo "$netstat_output" | awk '{print $5}')
            net_opkts=$(echo "$netstat_output" | awk '{print $7}')
            
            # Calcular ancho de banda aproximado
            net_bandwidth=$(echo "scale=2; ($net_ipkts + $net_opkts) / 1024" | bc)
            
            echo "$net_ipkts,$net_opkts,$net_bandwidth"
        else
            echo "N/A,N/A,N/A"
        fi
    else
        echo "N/A,N/A,N/A"
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
    local cpu_usage=$1
    local cpu_us=$2
    local cpu_sys=$3
    local cpu_idle=$4
    local cpu_wait=$5
    local mem_free_mb=$6
    local mem_swap_in=$7
    local mem_swap_out=$8
    local disk_read=$9
    local disk_write=${10}
    local disk_util=${11}
    local disk_await=${12}
    local net_ipkts=${13}
    local net_opkts=${14}
    local net_bandwidth=${15}
    local go_goroutines=${16}
    local go_heap=${17}
    local go_gc=${18}
    
    local alerts=()
    
    if [ "$cpu_usage" != "N/A" ] && [ $(echo "$cpu_usage > 80" | bc -l) -eq 1 ]; then
        alerts+=("CPU: ${cpu_usage}% (umbral: 80%)")
    fi
    
    if [ "$mem_free_mb" != "N/A" ] && [ $(echo "$mem_free_mb < 100" | bc -l) -eq 1 ]; then
        alerts+=("Memoria libre: ${mem_free_mb}MB (umbral: 100MB)")
    fi
    
    if [ "$disk_read" != "N/A" ] && [ $(echo "$disk_read > 100" | bc -l) -eq 1 ]; then
        alerts+=("Disco lectura: ${disk_read}kB/s (umbral: 100kB/s)")
    fi
    
    if [ "$disk_write" != "N/A" ] && [ $(echo "$disk_write > 100" | bc -l) -eq 1 ]; then
        alerts+=("Disco escritura: ${disk_write}kB/s (umbral: 100kB/s)")
    fi
    
    if [ "$disk_util" != "N/A" ] && [ $(echo "$disk_util > 90" | bc -l) -eq 1 ]; then
        alerts+=("Disco utilización: ${disk_util}% (umbral: 90%)")
    fi
    
    if [ "$net_ipkts" != "N/A" ] && [ $(echo "$net_ipkts > 10000" | bc -l) -eq 1 ]; then
        alerts+=("Red paquetes entrada: ${net_ipkts} (umbral: 10000)")
    fi
    
    if [ "$net_opkts" != "N/A" ] && [ $(echo "$net_opkts > 10000" | bc -l) -eq 1 ]; then
        alerts+=("Red paquetes salida: ${net_opkts} (umbral: 10000)")
    fi
    
    if [ "$net_bandwidth" != "N/A" ] && [ $(echo "$net_bandwidth > 100" | bc -l) -eq 1 ]; then
        alerts+=("Ancho de banda: ${net_bandwidth}MB/s (umbral: 100MB/s)")
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
    echo -e "${BLUE}=== Iniciando monitoreo con vmstat ===${NC}"
    echo -e "Intervalo: ${MONITOR_INTERVAL}s | Archivo: $CSV_FILE"
    
    # Crear archivo CSV con encabezados
    echo "timestamp,cpu_usage,cpu_us,cpu_sys,cpu_idle,cpu_wait,mem_free_mb,mem_swap_in,mem_swap_out,disk_read,disk_write,disk_util,disk_await,net_ipkts,net_opkts,net_bandwidth,go_goroutines,go_heap,go_gc" > "$CSV_FILE"
    
    # Guardar PID
    echo $$ > "$PID_FILE"
    
    # Iniciar bucle de monitoreo
    while true; do
        # Obtener timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Obtener métricas del sistema
        read -r vmstat_metrics <<< "$(get_vmstat_metrics)"
        cpu_usage=$(echo "$vmstat_metrics" | cut -d',' -f1)
        cpu_us=$(echo "$vmstat_metrics" | cut -d',' -f2)
        cpu_sys=$(echo "$vmstat_metrics" | cut -d',' -f3)
        cpu_idle=$(echo "$vmstat_metrics" | cut -d',' -f4)
        cpu_wait=$(echo "$vmstat_metrics" | cut -d',' -f5)
        mem_free_mb=$(echo "$vmstat_metrics" | cut -d',' -f6)
        mem_swap_in=$(echo "$vmstat_metrics" | cut -d',' -f7)
        mem_swap_out=$(echo "$vmstat_metrics" | cut -d',' -f8)
        
        # Obtener métricas de disco
        read -r disk_metrics <<< "$(get_disk_metrics)"
        disk_read=$(echo "$disk_metrics" | cut -d',' -f1)
        disk_write=$(echo "$disk_metrics" | cut -d',' -f2)
        disk_util=$(echo "$disk_metrics" | cut -d',' -f3)
        disk_await=$(echo "$disk_metrics" | cut -d',' -f4)
        
        # Obtener métricas de red
        read -r network_metrics <<< "$(get_network_metrics)"
        net_ipkts=$(echo "$network_metrics" | cut -d',' -f1)
        net_opkts=$(echo "$network_metrics" | cut -d',' -f2)
        net_bandwidth=$(echo "$network_metrics" | cut -d',' -f3)
        
        # Obtener métricas de Go
        read -r go_metrics <<< "$(get_go_metrics)"
        go_goroutines=$(echo "$go_metrics" | cut -d',' -f1)
        go_heap=$(echo "$go_metrics" | cut -d',' -f2)
        go_gc=$(echo "$go_metrics" | cut -d',' -f3)
        
        # Verificar umbrales
        check_thresholds "$cpu_usage" "$cpu_us" "$cpu_sys" "$cpu_idle" "$cpu_wait" "$mem_free_mb" "$mem_swap_in" "$mem_swap_out" "$disk_read" "$disk_write" "$disk_util" "$disk_await" "$net_ipkts" "$net_opkts" "$net_bandwidth" "$go_goroutines" "$go_heap" "$go_gc"
        
        # Escribir en CSV
        echo "$timestamp,$cpu_usage,$cpu_us,$cpu_sys,$cpu_idle,$cpu_wait,$mem_free_mb,$mem_swap_in,$mem_swap_out,$disk_read,$disk_write,$disk_util,$disk_await,$net_ipkts,$net_opkts,$net_bandwidth,$go_goroutines,$go_heap,$go_gc" >> "$CSV_FILE"
        
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