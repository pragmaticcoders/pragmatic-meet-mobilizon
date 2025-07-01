#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

COMPOSE_FILE="docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

echo -e "${BLUE}Mobilizon Quick Update${NC}"
echo "======================"

# Check if we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: $COMPOSE_FILE not found.${NC}"
    echo "Please run this script from the docker/production directory."
    exit 1
fi

echo -e "\n${BLUE}Pulling latest changes...${NC}"
cd ../..
git pull origin main
cd docker/production

echo -e "\n${BLUE}Building new image...${NC}"
$COMPOSE_CMD build

echo -e "\n${BLUE}Restarting containers...${NC}"
$COMPOSE_CMD down
$COMPOSE_CMD up -d

echo -e "\n${BLUE}Running migrations...${NC}"
$COMPOSE_CMD exec mobilizon /bin/mobilizon_ctl migrate

echo -e "\n${GREEN}✓ Quick update completed!${NC}"
echo "Application is available at: http://localhost:4000" 