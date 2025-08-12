#!/bin/bash

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

main() {
    echo -e "${YELLOW}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 🛑 STOPPING MOBILIZON SERVICES 🛑            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Stop Phoenix server
    print_step "Stopping Phoenix server..."
    if [ -f /tmp/phoenix.pid ]; then
        PHOENIX_PID=$(cat /tmp/phoenix.pid)
        if kill -0 $PHOENIX_PID 2>/dev/null; then
            kill $PHOENIX_PID
            print_success "Phoenix server stopped (PID: $PHOENIX_PID)"
            rm -f /tmp/phoenix.pid
        else
            print_warning "Phoenix server was not running (PID file existed but process not found)"
            rm -f /tmp/phoenix.pid
        fi
    else
        print_warning "No Phoenix PID file found"
    fi
    
    # Kill any remaining processes on our ports
    local ports=("4000" "5173")
    for port in "${ports[@]}"; do
        if port_in_use $port; then
            print_step "Killing processes on port $port..."
            pkill -f ".*:$port" 2>/dev/null || true
            sleep 1
            
            if port_in_use $port; then
                print_warning "Some processes may still be running on port $port"
                print_warning "You can manually kill them with: sudo lsof -ti :$port | xargs kill -9"
            else
                print_success "Port $port is now free"
            fi
        else
            print_success "Port $port is already free"
        fi
    done
    
    # Kill any remaining mix/elixir processes
    print_step "Cleaning up Elixir processes..."
    pkill -f "mix phx.server" 2>/dev/null || true
    pkill -f "beam.smp" 2>/dev/null || true
    
    # Kill any remaining npm/node processes
    print_step "Cleaning up Node.js processes..."
    pkill -f "vite" 2>/dev/null || true
    pkill -f "npm.*dev" 2>/dev/null || true
    
    # Cleanup log files
    print_step "Cleaning up log files..."
    rm -f /tmp/phoenix.log
    rm -f /tmp/phoenix.pid
    
    echo
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ CLEANUP COMPLETE! ✅                   ║"
    echo "║                                                              ║"
    echo "║  All Mobilizon development services have been stopped.      ║"
    echo "║                                                              ║"
    echo "║  🚀 To Start Again: ./scripts/dev-start.sh                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main "$@"