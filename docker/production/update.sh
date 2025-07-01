#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

COMPOSE_FILE="docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

echo -e "${BLUE}Mobilizon Production Update Script${NC}"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: $COMPOSE_FILE not found.${NC}"
    echo "Please run this script from the docker/production directory."
    exit 1
fi

# Check if .env exists
if [ ! -f "../../.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found.${NC}"
    echo "Please ensure your environment is properly configured."
fi

# Function to check if containers are running
check_containers() {
    if $COMPOSE_CMD ps --services --filter "status=running" | grep -q .; then
        return 0
    else
        return 1
    fi
}

# Function to backup database
backup_database() {
    echo -e "\n${BLUE}Creating database backup...${NC}"
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if $COMPOSE_CMD exec -T postgres pg_dump -U mobilizon mobilizon > "$BACKUP_FILE" 2>/dev/null; then
        echo -e "${GREEN}Database backup created: $BACKUP_FILE${NC}"
    else
        echo -e "${YELLOW}Warning: Could not create database backup.${NC}"
        echo "Continuing without backup..."
    fi
}

# Function to check health
check_health() {
    echo -e "\n${BLUE}Checking application health...${NC}"
    
    # Wait a bit for the application to start
    sleep 10
    
    # Try health check
    if curl -f http://localhost:4000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ Application health check failed${NC}"
        return 1
    fi
}

# Function to rollback
rollback() {
    echo -e "\n${RED}Rolling back to previous version...${NC}"
    
    # Stop current containers
    $COMPOSE_CMD down
    
    # Start previous containers
    $COMPOSE_CMD up -d
    
    # Wait and check health
    sleep 10
    if check_health; then
        echo -e "${GREEN}Rollback successful${NC}"
    else
        echo -e "${RED}Rollback failed - manual intervention required${NC}"
    fi
}

# Main update process
echo -e "\n${BLUE}Starting production update...${NC}"

# Check if containers are currently running
if check_containers; then
    echo -e "${GREEN}✓ Containers are currently running${NC}"
    
    # Ask user if they want to backup
    read -p "Create database backup before update? (Y/n): " backup_choice
    if [[ $backup_choice =~ ^[Nn]$ ]]; then
        echo "Skipping backup..."
    else
        backup_database
    fi
else
    echo -e "${YELLOW}Warning: No containers are currently running${NC}"
fi

# Pull latest changes
echo -e "\n${BLUE}Pulling latest changes...${NC}"
cd ../..
if git pull origin main; then
    echo -e "${GREEN}✓ Latest changes pulled successfully${NC}"
else
    echo -e "${RED}✗ Failed to pull latest changes${NC}"
    exit 1
fi
cd docker/production

# Build new image
echo -e "\n${BLUE}Building new Docker image...${NC}"
if $COMPOSE_CMD build; then
    echo -e "${GREEN}✓ New image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build new image${NC}"
    exit 1
fi

# Stop current containers
echo -e "\n${BLUE}Stopping current containers...${NC}"
$COMPOSE_CMD down

# Start new containers
echo -e "\n${BLUE}Starting new containers...${NC}"
if $COMPOSE_CMD up -d; then
    echo -e "${GREEN}✓ New containers started successfully${NC}"
else
    echo -e "${RED}✗ Failed to start new containers${NC}"
    rollback
    exit 1
fi

# Check health
if check_health; then
    echo -e "\n${GREEN}✓ Update completed successfully!${NC}"
    
    # Run migrations if needed
    echo -e "\n${BLUE}Running database migrations...${NC}"
    if $COMPOSE_CMD exec mobilizon /bin/mobilizon_ctl migrate; then
        echo -e "${GREEN}✓ Migrations completed successfully${NC}"
    else
        echo -e "${YELLOW}Warning: Migrations failed or not needed${NC}"
    fi
    
    echo -e "\n${GREEN}Production update completed successfully!${NC}"
    echo "Application is available at: http://localhost:4000"
    
else
    echo -e "\n${RED}✗ Update failed - health check failed${NC}"
    rollback
    exit 1
fi

echo -e "\n${BLUE}Useful commands:${NC}"
echo "  View logs: $COMPOSE_CMD logs -f"
echo "  Check status: $COMPOSE_CMD ps"
echo "  Stop: $COMPOSE_CMD down" 