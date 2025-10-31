# E2E Testing Environment

This directory contains the Docker configuration for running end-to-end tests with Playwright.

## Quick Start

From the project root, run:

```bash
./scripts/run-e2e-docker.sh
```

## Manual Usage

### 1. Build the Image

```bash
docker build -f docker/production/Dockerfile -t mobilizon-e2e:local .
```

### 2. Start Services

```bash
docker-compose -f docker/e2e/docker-compose.yml up -d
```

### 3. Run Tests

```bash
# Wait for the application to be ready
npx wait-on http://localhost:4000 -t 60000

# Run Playwright tests
npx playwright test
```

### 4. Cleanup

```bash
docker-compose -f docker/e2e/docker-compose.yml down -v
```

## Configuration

The `docker-compose.yml` file defines:

- **postgres**: PostGIS-enabled PostgreSQL database
- **mobilizon**: Mobilizon application built from production Dockerfile

### Environment Variables

Key environment variables for the Mobilizon service:

- `MOBILIZON_INSTANCE_HOST`: Set to "localhost" for local testing
- `MOBILIZON_DATABASE_HOST`: Points to the postgres service
- `MOBILIZON_INSTANCE_REGISTRATIONS_OPEN`: Set to "true" to allow test user registration

## Ports

- **4000**: Mobilizon application
- **5432**: PostgreSQL database

## Volumes

- `pgdata`: PostgreSQL data persistence (cleared with `down -v`)

## CI/CD

This setup mirrors the e2e testing configuration in `.github/workflows/ci-cd.yml` but is designed for local development and debugging.

## Troubleshooting

### View Logs

```bash
# All services
docker-compose -f docker/e2e/docker-compose.yml logs

# Specific service
docker-compose -f docker/e2e/docker-compose.yml logs mobilizon
docker-compose -f docker/e2e/docker-compose.yml logs postgres
```

### Check Service Status

```bash
docker-compose -f docker/e2e/docker-compose.yml ps
```

### Access Container Shell

```bash
docker-compose -f docker/e2e/docker-compose.yml exec mobilizon sh
```

### Port Conflicts

If ports 4000 or 5432 are already in use, modify the port mappings in `docker-compose.yml`:

```yaml
services:
  postgres:
    ports:
      - "5433:5432"  # Use host port 5433 instead
  mobilizon:
    ports:
      - "4001:4000"  # Use host port 4001 instead
```

Then update your test configuration accordingly.

