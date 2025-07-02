# Mobilizon Docker Setup

This directory contains Docker configurations for different environments and use cases.

## Directory Structure

- `development/` - Development environment with hot reloading
- `production/` - Production-ready configuration
- `testing/` - Testing environment with test database
- `multiarch/` - Multi-architecture Docker builds
- `tests/` - End-to-end testing setup

## Quick Start

### Development

```bash
# Start development environment
make setup
make start

# View logs
make logs

# Stop
make stop
```

### Production

```bash
# Copy and configure environment
cp env.prod.template .env
# Edit .env with your settings

# Deploy (includes PostgreSQL database)
docker compose -f docker/production/docker-compose.yml up -d

# Or use the interactive deployment script
cd docker/production
./deploy.sh

# Check health
curl http://localhost:4000/health
curl http://localhost:4000/health/detailed

# View logs
docker compose -f docker/production/docker-compose.yml logs -f
```

## Health Checks

The application provides two health check endpoints:

- `/health` - Simple health check (returns 200 OK if application is running)
- `/health/detailed` - Detailed health check (includes database connectivity)

These endpoints are used by Docker health checks and monitoring systems.

## Database Requirements

All environments require PostgreSQL with the following extensions:
- `postgis` - For geospatial features
- `pg_trgm` - For text search
- `unaccent` - For accent-insensitive search

The production entrypoint script automatically creates these extensions.

## Environment Configuration

### Development
- Uses `docker/development/docker-compose.yml`
- Includes PostgreSQL database
- Hot reloading enabled
- Environment file: `.env`

### Production
- Uses `docker/production/docker-compose.yml`
- **Includes internal PostgreSQL database with PostGIS**
- **Supports external database configuration**
- Expects external SMTP server
- Environment file: `.env`

### Testing
- Uses `docker/testing/docker-compose.yml`
- Includes test database
- Used for running tests

## Data Persistence

### Production Volumes
- `postgres_data` - PostgreSQL database data
- `mobilizon_uploads` - User uploaded files
- `mobilizon_timezones` - Timezone data
- `mobilizon_tzdata` - Timezone database
- `mobilizon_sitemap` - Generated sitemap files

### Backup and Restore
```bash
# Backup database
docker compose -f docker/production/docker-compose.yml exec postgres pg_dump -U mobilizon mobilizon > backup.sql

# Restore database
docker compose -f docker/production/docker-compose.yml exec -T postgres psql -U mobilizon mobilizon < backup.sql
```

## Updating Production

When you make changes to the source code on your production server, you need to rebuild and redeploy.

### Update Scripts

| Script | Purpose | Safety Features |
|--------|---------|-----------------|
| `update.sh` | Full update with safety checks | Backup, health checks, rollback |
| `quick-update.sh` | Fast update without prompts | Basic health check |
| `restart.sh` | Restart containers only | Health verification |

### Quick Update Workflow

```bash
# Navigate to production directory
cd docker/production

# Run interactive update (recommended)
./update.sh

# Or run quick update
./quick-update.sh

# Or just restart
./restart.sh
```

### Manual Update

```bash
# Pull changes and rebuild
git pull origin main
docker compose -f docker/production/docker-compose.yml build
docker compose -f docker/production/docker-compose.yml up -d
docker compose -f docker/production/docker-compose.yml exec mobilizon /bin/mobilizon_ctl migrate
```

## SMTP Configuration

All environments require SMTP configuration for email functionality. See [SMTP_OPTIONS.md](../SMTP_OPTIONS.md) for detailed configuration options.

## OAuth Authentication

Mobilizon supports multiple OAuth providers for user authentication including LinkedIn, Google, GitHub, Facebook, Discord, GitLab, Twitter, and Keycloak. See [OAUTH_SETUP.md](../OAUTH_SETUP.md) for detailed configuration instructions.

## Production Deployment

For detailed production deployment instructions, see [PRODUCTION_DEPLOYMENT.md](../PRODUCTION_DEPLOYMENT.md).

### Known Issues - Production CLI Commands

⚠️ **Important**: In production Docker deployments, `mobilizon_ctl` commands cannot be run directly on running containers due to distributed Erlang RPC issues.

**Affected commands**: `users.new`, `users.show`, `actors.new`, etc.

**Workaround**: Add CLI commands to the startup script:
1. Edit `docker/production/docker-entrypoint.sh`
2. Add commands before `echo "-- Starting!"` using:
   ```bash
   MOBILIZON_CTL_RPC_DISABLED=true /bin/mobilizon_ctl [command]
   ```
3. Rebuild and restart the container

This limitation does not affect development environments or non-Docker installations.

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Verify database credentials in environment file
   - Check if required extensions are installed
   - Ensure database is accessible from container

2. **Health Check Failures**
   - Check application logs: `docker compose logs mobilizon`
   - Verify database connectivity: `curl http://localhost:4000/health/detailed`
   - Check container status: `docker compose ps`

3. **Permission Issues**
   - Fix upload directory permissions: `docker compose exec mobilizon chown -R nobody:nobody /var/lib/mobilizon/`

4. **CLI Commands (`mobilizon_ctl`) Crash Container** 
   - **Issue**: Running `docker exec mobilizon_prod /bin/mobilizon_ctl users.new ...` causes container to restart
   - **Root Cause**: Distributed Erlang RPC configuration issue in production release
   - **Workaround**: Add CLI commands to `docker/production/docker-entrypoint.sh` with `MOBILIZON_CTL_RPC_DISABLED=true`
   - **Example**:
     ```bash
     # In docker-entrypoint.sh, add before "echo '-- Starting!'"
     MOBILIZON_CTL_RPC_DISABLED=true /bin/mobilizon_ctl users.new "admin@example.com" --admin --password "password"
     ```
   - **Note**: This issue only affects production Docker deployments. Development and direct installations work normally.

### Debug Commands

```bash
# Check container status
docker compose ps

# View logs
docker compose logs mobilizon

# Access container shell
docker compose exec mobilizon sh

# Check environment variables
docker compose exec mobilizon env | grep MOBILIZON
```

## Migration from Old Structure

If you were using the old Docker structure:

1. **Old**: `docker-compose.yml` → **New**: `docker/development/docker-compose.yml`
2. **Old**: `docker-compose.test.yml` → **New**: `docker/testing/docker-compose.yml`
3. **Old**: `Dockerfile` → **New**: `docker/development/Dockerfile`
4. **Dev Container**: Stays in `.devcontainer/` but now uses `docker/development/docker-compose.yml`

Update your commands accordingly. 