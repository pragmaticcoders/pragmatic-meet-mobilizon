#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Mobilizon Production Deployment${NC}"
echo "=================================="

# Check if .env exists
if [ ! -f "../../.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found.${NC}"
    echo "Please copy env.prod.template to .env and configure it first."
    echo "Run: cp env.prod.template .env"
    exit 1
fi

# Ask user about database configuration
echo -e "\n${BLUE}Database Configuration:${NC}"
echo "1. Internal PostgreSQL (recommended for most deployments)"
echo "2. External PostgreSQL (for advanced users with existing database)"
echo ""
read -p "Choose database configuration (1 or 2): " db_choice

case $db_choice in
    1)
        echo -e "\n${GREEN}Deploying with internal PostgreSQL database...${NC}"
        echo "This will start both Mobilizon and PostgreSQL containers."
        echo ""
        
        # Check if user wants to proceed
        read -p "Continue? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            echo -e "\n${GREEN}Starting deployment...${NC}"
            docker compose -f docker-compose.yml up -d
            
            echo -e "\n${GREEN}Deployment completed!${NC}"
            echo "Application should be available at: http://localhost:4000"
            echo ""
            echo "Useful commands:"
            echo "  View logs: docker compose -f docker-compose.yml logs -f"
            echo "  Check health: curl http://localhost:4000/health"
            echo "  Stop: docker compose -f docker-compose.yml down"
        else
            echo -e "${YELLOW}Deployment cancelled.${NC}"
            exit 0
        fi
        ;;
    2)
        echo -e "\n${GREEN}Deploying with external PostgreSQL database...${NC}"
        echo "Make sure your .env is configured with external database settings."
        echo ""
        
        # Check if user wants to proceed
        read -p "Continue? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            echo -e "\n${GREEN}Starting deployment with external database...${NC}"
            docker compose -f docker-compose.yml -f docker-compose.external-db.yml up -d
            
            echo -e "\n${GREEN}Deployment completed!${NC}"
            echo "Application should be available at: http://localhost:4000"
            echo ""
            echo "Useful commands:"
            echo "  View logs: docker compose -f docker-compose.yml -f docker-compose.external-db.yml logs -f"
            echo "  Check health: curl http://localhost:4000/health"
            echo "  Stop: docker compose -f docker-compose.yml -f docker-compose.external-db.yml down"
        else
            echo -e "${YELLOW}Deployment cancelled.${NC}"
            exit 0
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice. Please run the script again and choose 1 or 2.${NC}"
        exit 1
        ;;
esac 