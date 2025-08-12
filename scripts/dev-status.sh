#!/bin/bash

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local service=$1
    local status=$2
    local details=$3
    
    if [ "$status" = "running" ]; then
        echo -e "  ${GREEN}✅${NC} $service: ${GREEN}Running${NC} $details"
    elif [ "$status" = "stopped" ]; then
        echo -e "  ${RED}❌${NC} $service: ${RED}Stopped${NC} $details"
    else
        echo -e "  ${YELLOW}⚠️${NC} $service: ${YELLOW}Unknown${NC} $details"
    fi
}

check_port() {
    local port=$1
    if lsof -i :$port >/dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}

check_url() {
    local url=$1
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [ "$status_code" = "200" ]; then
        echo "running"
    else
        echo "stopped"
    fi
}

main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 📊 MOBILIZON SERVICE STATUS 📊               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "🔍 Checking services..."
    echo
    
    # Check PostgreSQL
    if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
        print_status "PostgreSQL Database" "running" "(localhost:5432)"
    else
        print_status "PostgreSQL Database" "stopped" "(localhost:5432)"
    fi
    
    # Check Phoenix server
    phoenix_port_status=$(check_port 4000)
    phoenix_url_status=$(check_url "http://localhost:4000")
    
    if [ "$phoenix_port_status" = "running" ] && [ "$phoenix_url_status" = "running" ]; then
        print_status "Phoenix Server" "running" "(http://localhost:4000)"
    elif [ "$phoenix_port_status" = "running" ]; then
        print_status "Phoenix Server" "unknown" "(port 4000 occupied but not responding)"
    else
        print_status "Phoenix Server" "stopped" "(http://localhost:4000)"
    fi
    
    # Check GraphQL API
    if [ "$phoenix_url_status" = "running" ]; then
        graphql_response=$(curl -s "http://localhost:4000/api/graphql" \
            -H "Content-Type: application/json" \
            -d '{"query":"query { __schema { queryType { name } } }"}' 2>/dev/null || echo "")
        
        if echo "$graphql_response" | grep -q "queryType"; then
            print_status "GraphQL API" "running" "(http://localhost:4000/api/graphql)"
        else
            print_status "GraphQL API" "stopped" "(endpoint not responding)"
        fi
    else
        print_status "GraphQL API" "stopped" "(Phoenix server not running)"
    fi
    
    # Check for running processes
    echo
    echo "🔍 Process Information:"
    
    # Check Phoenix processes
    phoenix_processes=$(pgrep -f "mix phx.server" 2>/dev/null | wc -l)
    beam_processes=$(pgrep -f "beam.smp" 2>/dev/null | wc -l)
    
    if [ "$phoenix_processes" -gt 0 ] || [ "$beam_processes" -gt 0 ]; then
        echo -e "  ${GREEN}•${NC} Elixir/Phoenix processes: $phoenix_processes mix processes, $beam_processes beam processes"
    else
        echo -e "  ${RED}•${NC} No Elixir/Phoenix processes found"
    fi
    
    # Check Node processes
    node_processes=$(pgrep -f "node\|npm\|vite" 2>/dev/null | wc -l)
    if [ "$node_processes" -gt 0 ]; then
        echo -e "  ${GREEN}•${NC} Node.js processes: $node_processes running"
    else
        echo -e "  ${YELLOW}•${NC} No Node.js processes found"
    fi
    
    # Check PID files
    echo
    echo "🔍 PID Files:"
    if [ -f /tmp/phoenix.pid ]; then
        phoenix_pid=$(cat /tmp/phoenix.pid)
        if kill -0 $phoenix_pid 2>/dev/null; then
            echo -e "  ${GREEN}•${NC} Phoenix PID file: $phoenix_pid (process running)"
        else
            echo -e "  ${RED}•${NC} Phoenix PID file: $phoenix_pid (process not found)"
        fi
    else
        echo -e "  ${YELLOW}•${NC} No Phoenix PID file found"
    fi
    
    # Check log files
    echo
    echo "🔍 Log Files:"
    if [ -f /tmp/phoenix.log ]; then
        log_size=$(wc -c < /tmp/phoenix.log)
        echo -e "  ${GREEN}•${NC} Phoenix log: /tmp/phoenix.log (${log_size} bytes)"
        echo -e "  ${BLUE}•${NC} Recent log entries:"
        tail -n 3 /tmp/phoenix.log | sed 's/^/    /'
    else
        echo -e "  ${YELLOW}•${NC} No Phoenix log file found"
    fi
    
    # Test attendees feature
    if [ "$phoenix_url_status" = "running" ]; then
        echo
        echo "🔍 Testing Attendees Feature:"
        
        attendees_test=$(curl -s "http://localhost:4000/api/graphql" \
            -H "Content-Type: application/json" \
            -d '{"query":"query TestParticipants($uuid: UUID!) { event(uuid: $uuid) { id uuid participants(limit: 2) { elements { id role actor { name } } } } }", "variables": {"uuid": "d5b63687-ab95-4167-9af3-5798fb60b373"}}' 2>/dev/null || echo "")
        
        if echo "$attendees_test" | grep -q "participants"; then
            participant_count=$(echo "$attendees_test" | jq -r '.data.event.participants.elements | length' 2>/dev/null || echo "0")
            print_status "Attendees API" "running" "(found $participant_count participants)"
            
            if [ "$participant_count" -gt 0 ]; then
                echo -e "  ${BLUE}•${NC} Test event: http://localhost:4000/events/d5b63687-ab95-4167-9af3-5798fb60b373"
            fi
        else
            print_status "Attendees API" "stopped" "(API not responding correctly)"
        fi
    fi
    
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Overall status
    if [ "$phoenix_url_status" = "running" ]; then
        echo -e "${GREEN}🎉 Mobilizon is running and ready for development!${NC}"
        echo -e "   Access your application at: ${BLUE}http://localhost:4000${NC}"
    else
        echo -e "${YELLOW}⚠️  Mobilizon is not fully running.${NC}"
        echo -e "   Start with: ${BLUE}./scripts/dev-start.sh${NC}"
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"