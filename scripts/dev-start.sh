#!/bin/bash

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_step "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within $((max_attempts * 2)) seconds"
    return 1
}

# Function to kill processes on specific ports
cleanup_ports() {
    local ports=("4000" "5173")
    
    for port in "${ports[@]}"; do
        if port_in_use $port; then
            print_warning "Port $port is in use, attempting to free it..."
            pkill -f ".*:$port" 2>/dev/null || true
            sleep 2
        fi
    done
}

# Main startup function
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 🎉 MOBILIZON DEV CONTAINER STARTUP 🎉        ║"
    echo "║                                                              ║"
    echo "║  Starting complete Mobilizon development environment...      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Check required tools
    print_step "Checking required dependencies..."
    
    local required_tools=("mix" "npm" "node" "elixir" "psql")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            print_error "Required tool '$tool' is not installed"
            exit 1
        fi
    done
    print_success "All required tools are available"
    
    # Check PostgreSQL connection
    print_step "Checking database connection..."
    if ! pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
        print_error "PostgreSQL is not running or not accessible"
        print_warning "Make sure PostgreSQL is running on localhost:5432"
        exit 1
    fi
    print_success "Database connection verified"
    
    # Cleanup any existing processes
    print_step "Cleaning up existing processes..."
    cleanup_ports
    
    # Install/update dependencies
    print_step "Installing Elixir dependencies..."
    mix deps.get
    
    print_step "Installing Node.js dependencies..."
    npm install
    
    # Setup database (if needed)
    print_step "Setting up database..."
    if mix ecto.create 2>/dev/null; then
        print_success "Database created"
    else
        print_warning "Database already exists or creation skipped"
    fi
    
    # Run migrations
    print_step "Running database migrations..."
    mix ecto.migrate
    
    # Seed database (if needed)
    print_step "Seeding database with test data..."
    mix run priv/repo/seeds.exs 2>/dev/null || print_warning "Database seeding skipped (may already be seeded)"
    
    # Build frontend assets
    print_step "Building frontend assets..."
    npm run build
    
    # Start Phoenix server in background
    print_step "Starting Phoenix server (backend)..."
    export MIX_ENV=dev
    export MOBILIZON_INSTANCE_HOST=localhost
    export MOBILIZON_INSTANCE_PORT=4000
    export MOBILIZON_INSTANCE_REGISTRATIONS_OPEN=true
    export MOBILIZON_INSTANCE_SECRET_KEY_BASE=changethis
    export MOBILIZON_INSTANCE_SECRET_KEY=changethis
    
    # Start Phoenix server
    nohup mix phx.server > /tmp/phoenix.log 2>&1 &
    PHOENIX_PID=$!
    echo $PHOENIX_PID > /tmp/phoenix.pid
    
    # Wait for Phoenix to be ready
    if wait_for_service "http://localhost:4000" "Phoenix server"; then
        print_success "Backend is running on http://localhost:4000"
    else
        print_error "Failed to start Phoenix server"
        cat /tmp/phoenix.log
        exit 1
    fi
    
    # Test the attendees feature
    print_step "Testing attendees feature API..."
    sleep 5  # Give a moment for the server to fully initialize
    
    RESPONSE=$(curl -s "http://localhost:4000/api/graphql" \
        -H "Content-Type: application/json" \
        -d '{"query":"query { events(limit: 1) { elements { id uuid title } } }"}' 2>/dev/null || echo "")
    
    if echo "$RESPONSE" | grep -q "events"; then
        print_success "GraphQL API is responding correctly"
    else
        print_warning "GraphQL API test failed, but server may still be starting"
    fi
    
    # Success message
    echo
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 STARTUP COMPLETE! 🚀                   ║"
    echo "║                                                              ║"
    echo "║  Your Mobilizon application is now running with:            ║"
    echo "║                                                              ║"
    echo "║  🌐 Frontend & Backend: http://localhost:4000               ║"
    echo "║  📊 GraphQL Playground: http://localhost:4000/api/graphql   ║"
    echo "║  🗃️  Database: PostgreSQL on localhost:5432                ║"
    echo "║                                                              ║"
    echo "║  ✨ Features Available:                                     ║"
    echo "║     • Public attendees list (above comments)                ║"
    echo "║     • Auto-refresh when users join/leave                    ║"
    echo "║     • Full event management                                  ║"
    echo "║     • User registration & authentication                     ║"
    echo "║                                                              ║"
    echo "║  📝 Test Event with Attendees:                              ║"
    echo "║     http://localhost:4000/events/d5b63687-ab95-4167-9af3-5798fb60b373 ║"
    echo "║                                                              ║"
    echo "║  🛑 To Stop: ./scripts/dev-stop.sh                          ║"
    echo "║  📋 Logs: tail -f /tmp/phoenix.log                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_step "Monitoring server health..."
    echo "Press Ctrl+C to stop monitoring (servers will continue running)"
    echo
    
    # Monitor the services
    while true; do
        if ! kill -0 $PHOENIX_PID 2>/dev/null; then
            print_error "Phoenix server has stopped unexpectedly!"
            print_warning "Check logs with: tail -f /tmp/phoenix.log"
            exit 1
        fi
        
        # Check if services are responding
        if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:4000" | grep -q "200"; then
            print_warning "Phoenix server may be having issues..."
        fi
        
        sleep 10
    done
}

# Trap Ctrl+C
trap 'echo -e "\n${YELLOW}[INFO]${NC} Monitoring stopped. Services are still running."; exit 0' INT

# Run main function
main "$@"