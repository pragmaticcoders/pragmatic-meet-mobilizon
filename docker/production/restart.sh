#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

COMPOSE_FILE="docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

echo -e "${BLUE}Mobilizon Restart${NC}"
echo "================"

# Check if we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: $COMPOSE_FILE not found.${NC}"
    echo "Please run this script from the docker/production directory."
    exit 1
fi

echo -e "\n${BLUE}Restarting containers...${NC}"
$COMPOSE_CMD restart

echo -e "\n${BLUE}Checking health...${NC}"
sleep 5

if curl -f http://localhost:4000/health > /dev/null 2>&1; then
    echo -e "\n${GREEN}✓ Restart completed successfully!${NC}"
    echo "Application is available at: http://localhost:4000"
else
    echo -e "\n${RED}✗ Health check failed${NC}"
    echo "Check logs: $COMPOSE_CMD logs -f"
fi 