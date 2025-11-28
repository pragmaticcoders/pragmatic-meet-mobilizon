#!/bin/bash

echo "🐳 Running E2E tests with Docker"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if services were started
SERVICES_STARTED=false

# Function to cleanup
cleanup() {
    local exit_code=$?
    if [ "$SERVICES_STARTED" = true ]; then
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up...${NC}"
        docker compose -f docker/e2e/docker-compose.yml down -v 2>/dev/null || true
    fi
    exit $exit_code
}

# Trap EXIT and INT to ensure cleanup happens
trap cleanup EXIT INT TERM

# Step 1: Build the Docker image
echo -e "${GREEN}📦 Step 1: Building Docker image...${NC}"
if docker build -f docker/production/Dockerfile -t mobilizon-e2e:local .; then
    echo ""
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
    echo ""
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

# Step 2: Start services
echo -e "${GREEN}🚀 Step 2: Starting services...${NC}"
if docker compose -f docker/e2e/docker-compose.yml up -d; then
    SERVICES_STARTED=true
    echo ""
    echo -e "${GREEN}✅ Services started${NC}"
    echo ""
else
    echo -e "${RED}❌ Failed to start services${NC}"
    exit 1
fi

# Step 3: Wait for application to be ready
echo -e "${GREEN}⏳ Step 3: Waiting for application to be ready...${NC}"
if npx wait-on http://localhost:4000 -t 60000; then
    echo ""
    echo -e "${GREEN}✅ Application is ready${NC}"
    echo ""
else
    echo -e "${RED}❌ Application failed to start within 60 seconds${NC}"
    echo ""
    echo "Docker logs:"
    docker compose -f docker/e2e/docker-compose.yml logs mobilizon
    exit 1
fi

# Step 4: Install Playwright browsers
echo -e "${GREEN}🎭 Step 4: Ensuring Playwright browsers are installed...${NC}"
npx playwright install --with-deps chromium firefox
echo ""

# Step 5: Run E2E tests
echo -e "${GREEN}🧪 Step 5: Running E2E tests...${NC}"
echo ""

# Disable trap temporarily to handle test failures gracefully
trap - EXIT
npx playwright test "$@"
TEST_EXIT_CODE=$?

# Re-enable cleanup
if [ "$SERVICES_STARTED" = true ]; then
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    docker compose -f docker/e2e/docker-compose.yml down -v 2>/dev/null || true
fi

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo ""
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo -e "${YELLOW}📊 To view the test report, run: npx playwright show-report${NC}"
fi

exit $TEST_EXIT_CODE
