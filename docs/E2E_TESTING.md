# E2E Testing with Docker

This guide explains how to run end-to-end tests locally using Docker, mimicking the CI/CD pipeline.

## Prerequisites

- Docker and Docker Compose
- Node.js 20+ (for Playwright)
- npm dependencies installed (`npm ci` or `npm install`)

## Quick Start

The easiest way to run E2E tests with Docker is using the provided script:

```bash
./scripts/run-e2e-docker.sh
```

This script will:
1. Build the Docker image from the production Dockerfile
2. Start PostgreSQL and Mobilizon containers
3. Wait for the application to be ready
4. Install Playwright browsers (if needed)
5. Run all E2E tests
6. Clean up containers automatically

## Running Specific Tests

You can pass any Playwright arguments to the script:

```bash
# Run a specific test file
./scripts/run-e2e-docker.sh tests/e2e/login.spec.ts

# Run with UI mode
./scripts/run-e2e-docker.sh --ui

# Run in headed mode (see the browser)
./scripts/run-e2e-docker.sh --headed

# Run only chromium tests
./scripts/run-e2e-docker.sh --project=chromium

# Run with debug mode
./scripts/run-e2e-docker.sh --debug
```

## Manual Setup (Step by Step)

If you prefer to run the steps manually:

### 1. Build the Docker Image

```bash
docker build -f docker/production/Dockerfile -t mobilizon-e2e:local .
```

This may take 10-20 minutes on the first run as it builds the frontend assets and backend release.

### 2. Start the Services

```bash
docker-compose -f docker/e2e/docker-compose.yml up -d
```

This starts:
- PostgreSQL with PostGIS
- Mobilizon application on port 4000

### 3. Wait for the Application

```bash
npx wait-on http://localhost:4000 -t 60000
```

Or manually check:
```bash
curl http://localhost:4000
```

### 4. Run the Tests

```bash
npx playwright test
```

### 5. Cleanup

```bash
docker-compose -f docker/e2e/docker-compose.yml down -v
```

The `-v` flag removes volumes, ensuring a clean state for the next run.

## Viewing Test Results

After running tests, view the HTML report:

```bash
npx playwright show-report
```

## Troubleshooting

### Application Not Starting

Check the logs:
```bash
docker-compose -f docker/e2e/docker-compose.yml logs mobilizon
```

### Database Connection Issues

Ensure PostgreSQL is healthy:
```bash
docker-compose -f docker/e2e/docker-compose.yml ps
```

Check database logs:
```bash
docker-compose -f docker/e2e/docker-compose.yml logs postgres
```

### Port Already in Use

If port 4000 or 5432 is already in use, you can either:
1. Stop the conflicting service
2. Modify `docker/e2e/docker-compose.yml` to use different ports

### Playwright Browsers Not Installed

Install them manually:
```bash
npx playwright install --with-deps
```

### Build Cache Issues

Clear Docker build cache and rebuild:
```bash
docker build --no-cache -f docker/production/Dockerfile -t mobilizon-e2e:local .
```

## Differences from CI/CD

The local setup differs slightly from CI/CD:
- **CI**: Pulls pre-built image from Docker Hub
- **Local**: Builds image locally
- **CI**: Uses GitHub Actions services for PostgreSQL
- **Local**: Uses docker-compose for all services

## Performance Tips

### Faster Rebuilds

To avoid rebuilding the entire Docker image every time:

1. **Keep the image**: Don't delete `mobilizon-e2e:local` between test runs
2. **Only rebuild when needed**: Only rebuild if you've changed backend/frontend code
3. **Use layer caching**: Docker will reuse unchanged layers

### Parallel Testing

Run tests in parallel (default):
```bash
npx playwright test --workers=4
```

Or disable parallel execution:
```bash
npx playwright test --workers=1
```

## Test Data

The application in Docker uses a clean database on each run. Unlike local development, you won't have pre-seeded test users.

To seed test data, you would need to:
1. Access the container: `docker-compose -f docker-compose.e2e.local.yml exec mobilizon sh`
2. Run migrations and seeds manually

However, the E2E tests are designed to work with a fresh instance and create necessary data during test execution.

## CI/CD Comparison

This local setup mirrors the CI/CD pipeline defined in `.github/workflows/ci-cd.yml` (lines 140-235):

| Step | CI/CD | Local |
|------|-------|-------|
| Image Source | Docker Hub | Built locally |
| Database | GitHub Actions service | docker-compose |
| Wait Strategy | wait-on | wait-on |
| Test Execution | Playwright | Playwright |
| Cleanup | Automatic (workflow end) | Automatic (script trap) |

## Advanced Usage

### Custom Environment Variables

Edit `docker/e2e/docker-compose.yml` to add custom environment variables:

```yaml
services:
  mobilizon:
    environment:
      MOBILIZON_INSTANCE_NAME: "My Test Instance"
      # Add more variables...
```

### Debug Mode

Keep containers running after tests:

```bash
docker-compose -f docker/e2e/docker-compose.yml up -d
# Run tests manually
npx playwright test
# Inspect at http://localhost:4000
# Clean up when done
docker-compose -f docker/e2e/docker-compose.yml down -v
```

### Using a Different Tag

Build with a specific tag:
```bash
docker build -f docker/production/Dockerfile -t mobilizon-e2e:my-feature .
```

Update `docker/e2e/docker-compose.yml` to use your tag:
```yaml
services:
  mobilizon:
    image: mobilizon-e2e:my-feature
```

