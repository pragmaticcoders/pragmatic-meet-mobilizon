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

echo -e "${BLUE}Mobilizon Production Management${NC}"
echo "================================"

# Check if we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: $COMPOSE_FILE not found.${NC}"
    echo "Please run this script from the docker/production directory."
    exit 1
fi

# Function to show status
show_status() {
    echo -e "\n${BLUE}Container Status:${NC}"
    $COMPOSE_CMD ps
    
    echo -e "\n${BLUE}Health Check:${NC}"
    if curl -f http://localhost:4000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is healthy${NC}"
    else
        echo -e "${RED}✗ Application health check failed${NC}"
    fi
}

# Function to show logs
show_logs() {
    echo -e "\n${BLUE}Recent logs (last 50 lines):${NC}"
    $COMPOSE_CMD logs --tail=50
}

# Function to backup database
backup_db() {
    echo -e "\n${BLUE}Creating database backup...${NC}"
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if $COMPOSE_CMD exec -T postgres pg_dump -U mobilizon mobilizon > "$BACKUP_FILE" 2>/dev/null; then
        echo -e "${GREEN}Database backup created: $BACKUP_FILE${NC}"
    else
        echo -e "${RED}Failed to create database backup${NC}"
    fi
}

# Main menu
while true; do
    echo -e "\n${BLUE}Available Operations:${NC}"
    echo "1.  Show status"
    echo "2.  Show logs"
    echo "3.  Start application"
    echo "4.  Stop application"
    echo "5.  Restart application"
    echo "6.  Update application (interactive)"
    echo "7.  Quick update"
    echo "8.  Backup database"
    echo "9.  Run migrations"
    echo "10. Health check"
    echo "11. Access container shell"
    echo "12. View environment variables"
    echo "0.  Exit"
    
    echo ""
    read -p "Choose an operation (0-12): " choice
    
    case $choice in
        1)
            show_status
            ;;
        2)
            show_logs
            ;;
        3)
            echo -e "\n${BLUE}Starting application...${NC}"
            $COMPOSE_CMD up -d
            echo -e "${GREEN}Application started${NC}"
            ;;
        4)
            echo -e "\n${BLUE}Stopping application...${NC}"
            $COMPOSE_CMD down
            echo -e "${GREEN}Application stopped${NC}"
            ;;
        5)
            echo -e "\n${BLUE}Restarting application...${NC}"
            $COMPOSE_CMD restart
            echo -e "${GREEN}Application restarted${NC}"
            ;;
        6)
            echo -e "\n${BLUE}Running interactive update...${NC}"
            ./update.sh
            ;;
        7)
            echo -e "\n${BLUE}Running quick update...${NC}"
            ./quick-update.sh
            ;;
        8)
            backup_db
            ;;
        9)
            echo -e "\n${BLUE}Running migrations...${NC}"
            if $COMPOSE_CMD exec mobilizon /bin/mobilizon_ctl migrate; then
                echo -e "${GREEN}Migrations completed successfully${NC}"
            else
                echo -e "${RED}Migrations failed${NC}"
            fi
            ;;
        10)
            echo -e "\n${BLUE}Health Check:${NC}"
            echo "Simple health check:"
            curl -s http://localhost:4000/health | jq . 2>/dev/null || curl -s http://localhost:4000/health
            echo -e "\nDetailed health check:"
            curl -s http://localhost:4000/health/detailed | jq . 2>/dev/null || curl -s http://localhost:4000/health/detailed
            ;;
        11)
            echo -e "\n${BLUE}Accessing container shell...${NC}"
            echo "Type 'exit' to return to this menu"
            $COMPOSE_CMD exec mobilizon sh
            ;;
        12)
            echo -e "\n${BLUE}Environment Variables:${NC}"
            $COMPOSE_CMD exec mobilizon env | grep MOBILIZON | sort
            ;;
        0)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid choice. Please select 0-12.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done 