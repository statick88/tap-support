#!/usr/bin/env bash
# =============================================================================
# TikTok Tap Support - Multi-Instance Launcher
# Built by Statick | https://statick.dev
# 
# This script allows running multiple tap-support instances in parallel
# Each instance has its own storage directory and configuration
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="${SCRIPT_DIR}/bin/tap-support"
DEFAULT_TAP_RATE=10
MAX_INSTANCES=10

# Default values
USERNAME=""
TAP_RATE=$DEFAULT_TAP_RATE
INSTANCE_ID=""
AUTO_TAP=true

usage() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  TikTok Tap Support - Multi-Instance Launcher${NC}"
    echo -e "${BLUE}  Built by Statick | https://statick.dev${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo "  $0 [options] [username]"
    echo ""
    echo -e "${GREEN}Options:${NC}"
    echo "  -r, --rate RATE     Taps per second (default: $DEFAULT_TAP_RATE)"
    echo "  -i, --id ID         Instance ID for parallel execution"
    echo "  -n, --no-auto       Disable auto-tapping (manual mode)"
    echo "  -s, --stop ID       Stop a running instance"
    echo "  -l, --list          List running instances"
    echo "  -k, --killall       Stop all running instances"
    echo "  -h, --help          Show this help"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0 yazgardea                    # Run with username yazgardea (auto-tap)"
    echo "  $0 -r 20 user1                  # Run with 20 taps/sec"
    echo "  $0 -i instance1 user1           # Run with custom instance ID"
    echo "  $0 -i instance1 -n user1        # Manual mode (no auto-tap)"
    echo "  $0 --list                        # List running instances"
    echo "  $0 --stop instance1             # Stop specific instance"
    echo "  $0 --killall                     # Stop all instances"
    echo ""
}

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}Error: Binary not found at $BINARY_PATH${NC}"
    echo "Run 'make build' first to build the application."
    exit 1
fi

# PID file management
PID_DIR="${SCRIPT_DIR}/.pids"
mkdir -p "$PID_DIR"

get_pid_file() {
    local id="$1"
    echo "${PID_DIR}/tap-${id}.pid"
}

is_running() {
    local pid_file=$(get_pid_file "$1")
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        rm -f "$pid_file"
    fi
    return 1
}

get_pid() {
    local pid_file=$(get_pid_file "$1")
    if [ -f "$pid_file" ]; then
        cat "$pid_file"
    fi
}

list_instances() {
    echo ""
    echo -e "${BLUE}Running Instances:${NC}"
    echo ""
    printf "  ${CYAN}%-15s %-10s %-10s %-10s %s${NC}\n" "INSTANCE" "PID" "RATE" "STATUS" "USERNAME"
    echo "  ---------------------------------------------------------------------"
    
    local count=0
    for pid_file in "$PID_DIR"/*.pid; do
        if [ -f "$pid_file" ]; then
            local instance=$(basename "$pid_file" .pid | sed 's/tap-//')
            local pid=$(cat "$pid_file" 2>/dev/null)
            if kill -0 "$pid" 2>/dev/null; then
                local rate=$(grep -oP 'TIKTOK_TAP_RATE=\K[0-9]+' "/proc/$pid/environ" 2>/dev/null || echo "?")
                local user=$(grep -oP 'TIKTOK_USERNAME=\K[^ ]+' "/proc/$pid/environ" 2>/dev/null || echo "?")
                printf "  ${GREEN}%-15s${NC} %-10s %-10s %-10s %s\n" "$instance" "$pid" "${rate}/s" "Running" "${user:-?}"
                count=$((count + 1))
            else
                rm -f "$pid_file"
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "  ${YELLOW}No instances running${NC}"
    fi
    echo ""
}

stop_instance() {
    local instance="$1"
    local pid_file=$(get_pid_file "$instance")
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}Stopping instance $instance (PID: $pid)...${NC}"
            kill "$pid" 2>/dev/null || true
            sleep 1
            kill -9 "$pid" 2>/dev/null || true
            rm -f "$pid_file"
            echo -e "${GREEN}Instance $instance stopped${NC}"
        else
            rm -f "$pid_file"
            echo -e "${YELLOW}Instance $instance was not running${NC}"
        fi
    else
        echo -e "${RED}Instance $instance not found${NC}"
    fi
}

stop_all() {
    echo -e "${YELLOW}Stopping all instances...${NC}"
    for pid_file in "$PID_DIR"/*.pid; do
        if [ -f "$pid_file" ]; then
            local instance=$(basename "$pid_file" .pid | sed 's/tap-//')
            stop_instance "$instance"
        fi
    done
    echo -e "${GREEN}All instances stopped${NC}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rate)
            TAP_RATE="$2"
            shift 2
            ;;
        -i|--id)
            INSTANCE_ID="$2"
            shift 2
            ;;
        -n|--no-auto)
            AUTO_TAP=false
            shift
            ;;
        -s|--stop)
            stop_instance "$2"
            exit 0
            ;;
        -l|--list)
            list_instances
            exit 0
            ;;
        -k|--killall)
            stop_all
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
        *)
            USERNAME="$1"
            shift
            ;;
    esac
done

# Validate inputs
if [ -z "$USERNAME" ]; then
    echo -e "${RED}Error: Username is required${NC}"
    usage
    exit 1
fi

if [ -z "$INSTANCE_ID" ]; then
    INSTANCE_ID="${USERNAME}"
fi

# Check if instance is already running
if is_running "$INSTANCE_ID"; then
    echo -e "${RED}Error: Instance '$INSTANCE_ID' is already running${NC}"
    echo -e "${YELLOW}Use '$0 --stop $INSTANCE_ID' to stop it first${NC}"
    exit 1
fi

# Build instance label
INSTANCE_LABEL="[$INSTANCE_ID]"

# Show configuration
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Starting TikTok Tap Support${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Instance:${NC}  $INSTANCE_ID"
echo -e "  ${CYAN}Username:${NC}  $USERNAME"
echo -e "  ${CYAN}Rate:${NC}      $TAP_RATE taps/sec"
echo -e "  ${CYAN}Auto-tap:${NC}  $AUTO_TAP"
echo ""

# Set environment variables
export TIKTOK_USERNAME="$USERNAME"
export TIKTOK_TAP_RATE="$TAP_RATE"
export TIKTOK_INSTANCE_ID="$INSTANCE_ID"
export TIKTOK_STORAGE_PATH="./data"

if [ "$AUTO_TAP" = "true" ]; then
    export TIKTOK_AUTO_TAP="true"
fi

# Run the application interactively (Bubble Tea needs a real terminal)
echo -e "${GREEN}Starting tap-support...${NC}"
echo ""
exec "$BINARY_PATH"