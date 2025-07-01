# Mobilizon Production Deployment Guide

## Overview

This guide covers deploying Mobilizon in production using Docker Compose. The production setup includes an internal PostgreSQL database with PostGIS, but can also be configured to use external services.

## Prerequisites

- Docker and Docker Compose installed
- External SMTP server configuration
- Domain name and SSL certificate (recommended)

## Configuration

For detailed information about configuration options and environment variables, see [CONFIGURATION.md](CONFIGURATION.md).

## Quick Start

### Option 1: Interactive Deployment (Recommended)

```bash
# Copy and configure environment
cp env.prod.template .env
# Edit .env with your settings

# Use the interactive deployment script
cd docker/production
./deploy.sh
```

### Option 2: Manual Deployment

```bash
# Copy and configure environment
cp env.prod.template .env
# Edit .env with your settings

# Deploy with internal database
docker compose -f docker/production/docker-compose.yml up -d

# Or deploy with external database
docker compose -f docker/production/docker-compose.yml -f docker/production/docker-compose.external-db.yml up -d
```

### 1. Clone and Setup

```bash
git clone https://github.com/mobilizon/mobilizon.git
cd mobilizon
cp env.prod.template .env
```

### 2. Configure Environment

Edit `.env` with your production settings:

```bash
# Required: Database Configuration (Internal Docker DB)
MOBILIZON_DATABASE_USERNAME=mobilizon
MOBILIZON_DATABASE_PASSWORD=your-secure-database-password
MOBILIZON_DATABASE_DBNAME=mobilizon
MOBILIZON_DATABASE_HOST=postgres
MOBILIZON_DATABASE_PORT=5432
MOBILIZON_DATABASE_SSL=false

# Required: SMTP Configuration
MOBILIZON_SMTP_SERVER=smtp.gmail.com
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_USERNAME=your-email@gmail.com
MOBILIZON_SMTP_PASSWORD=your-app-password
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always

# Required: Instance Configuration
MOBILIZON_INSTANCE_NAME="Your Mobilizon Instance"
MOBILIZON_INSTANCE_HOST=your-domain.com
MOBILIZON_INSTANCE_EMAIL=noreply@your-domain.com
MOBILIZON_INSTANCE_SECRET_KEY_BASE=your-secret-key-base
MOBILIZON_INSTANCE_SECRET_KEY=your-secret-key
```

### 3. Deploy

```bash
# Start the application with database
docker compose -f docker/production/docker-compose.yml up -d

# Check logs
docker compose -f docker/production/docker-compose.yml logs -f
```

## Database Setup

### Internal PostgreSQL Database (Default)

The production setup includes a PostgreSQL database with PostGIS running in a container. The database data is persisted using Docker volumes.

**Features:**
- PostgreSQL 15 with PostGIS 3.3
- Automatic extension creation (postgis, pg_trgm, unaccent)
- Data persistence through Docker volumes
- Health checks and automatic restart

**Data Location:**
- Database data: `postgres_data` Docker volume
- Application data: Various `mobilizon_*` volumes

### External Database (Optional)

To use an external database instead of the internal one:

1. **Use the external database override file**:
   ```bash
   docker compose -f docker/production/docker-compose.yml -f docker/production/docker-compose.external-db.yml up -d
   ```

2. **Update environment variables** in `.env`:
   ```bash
   MOBILIZON_DATABASE_HOST=your-external-database-host
   MOBILIZON_DATABASE_SSL=true
   ```

3. **Ensure your external database has the required extensions**:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   CREATE EXTENSION IF NOT EXISTS unaccent;
   ```

**Alternative method** - Remove the postgres service manually:
1. Edit `docker/production/docker-compose.yml` and remove the `postgres` service
2. Remove the `depends_on` section from the `mobilizon` service
3. Update your `.env` with external database settings

### Database Migration

```bash
# Run migrations
docker compose -f docker/production/docker-compose.yml exec mobilizon /bin/mobilizon_ctl migrate
```

### Database Backup

```bash
# Backup internal database
docker compose -f docker/production/docker-compose.yml exec postgres pg_dump -U mobilizon mobilizon > backup.sql

# Restore internal database
docker compose -f docker/production/docker-compose.yml exec -T postgres psql -U mobilizon mobilizon < backup.sql
```

## SMTP Configuration

### External SMTP Setup

Configure your SMTP settings in `.env`:

```bash
# Gmail Example
MOBILIZON_SMTP_SERVER=smtp.gmail.com
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_USERNAME=your-email@gmail.com
MOBILIZON_SMTP_PASSWORD=your-app-password
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always

# SendGrid Example
MOBILIZON_SMTP_SERVER=smtp.sendgrid.net
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_USERNAME=apikey
MOBILIZON_SMTP_PASSWORD=your-sendgrid-api-key
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

### Test Email Configuration

```bash
# Test SMTP configuration
docker compose -f docker/production/docker-compose.yml exec mobilizon /bin/mobilizon_ctl test_email
```

## SSL/HTTPS Setup

### Reverse Proxy Configuration

Use a reverse proxy (nginx, traefik, etc.) to handle SSL termination:

```nginx
# Nginx example
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Environment Configuration

Set the scheme to HTTPS in your `.env`:

```bash
MOBILIZON_INSTANCE_SCHEME=https
```

## Monitoring and Maintenance

### Health Checks

```bash
# Simple health check (returns 200 OK if application is running)
curl -f http://localhost:4000/health

# Detailed health check (includes database connectivity)
curl -f http://localhost:4000/health/detailed

# Check database connectivity
docker compose -f docker/production/docker-compose.yml exec mobilizon pg_isready -h $MOBILIZON_DATABASE_HOST -p $MOBILIZON_DATABASE_PORT -U $MOBILIZON_DATABASE_USERNAME
```

### Logs

```bash
# View application logs
docker compose -f docker/production/docker-compose.yml logs mobilizon

# Follow logs in real-time
docker compose -f docker/production/docker-compose.yml logs -f mobilizon
```

## Updating Production

When you make modifications to the source files on your production server, you need to rebuild and redeploy the application.

### Option 1: Interactive Update (Recommended)

```bash
# Navigate to production directory
cd docker/production

# Run the interactive update script
./update.sh
```

This script will:
- ✅ Create database backup (optional)
- ✅ Pull latest changes from git
- ✅ Build new Docker image
- ✅ Restart containers
- ✅ Run database migrations
- ✅ Verify application health
- ✅ Rollback automatically if something goes wrong

### Option 2: Quick Update

```bash
# Navigate to production directory
cd docker/production

# Run quick update (no prompts)
./quick-update.sh
```

This script performs the same steps as the interactive update but without prompts.

### Option 3: Manual Update

```bash
# 1. Pull latest changes
git pull origin main

# 2. Navigate to production directory
cd docker/production

# 3. Build new image
docker compose -f docker-compose.yml build

# 4. Stop current containers
docker compose -f docker-compose.yml down

# 5. Start with new image
docker compose -f docker-compose.yml up -d

# 6. Run migrations
docker compose -f docker-compose.yml exec mobilizon /bin/mobilizon_ctl migrate

# 7. Check health
curl http://localhost:4000/health
```

### Option 4: Restart Only

If you only need to restart the containers (no code changes):

```bash
# Navigate to production directory
cd docker/production

# Restart containers
./restart.sh
```

### Update Scripts Overview

| Script | Purpose | Interactive | Backup | Rollback |
|--------|---------|-------------|---------|----------|
| `update.sh` | Full update with safety checks | ✅ Yes | ✅ Optional | ✅ Yes |
| `quick-update.sh` | Fast update without prompts | ❌ No | ❌ No | ❌ No |
| `restart.sh` | Restart containers only | ❌ No | ❌ No | ❌ No |

### Pre-Update Checklist

Before updating production:

1. **Test Changes**: Ensure your changes work in development
2. **Check Dependencies**: Verify any new dependencies are included
3. **Database Migrations**: Ensure migrations are backward compatible
4. **Backup**: Consider creating a database backup
5. **Maintenance Window**: Plan for potential downtime

### Post-Update Verification

After updating:

1. **Health Check**: Verify application is healthy
   ```bash
   curl http://localhost:4000/health/detailed
   ```

2. **Functionality Test**: Test key features of your application

3. **Monitor Logs**: Watch for any errors
   ```bash
   docker compose -f docker/production/docker-compose.yml logs -f
   ```

4. **Performance Check**: Ensure application performance is acceptable

### Rollback Procedure

If an update fails:

1. **Automatic Rollback**: The update script will attempt automatic rollback
2. **Manual Rollback**: If automatic rollback fails:
   ```bash
   # Stop current containers
   docker compose -f docker/production/docker-compose.yml down
   
   # Restore from backup (if available)
   docker compose -f docker/production/docker-compose.yml exec -T postgres psql -U mobilizon mobilizon < backup_file.sql
   
   # Start containers
   docker compose -f docker/production/docker-compose.yml up -d
   ```

### Backup

```bash
# Database backup
docker compose -f docker/production/docker-compose.yml exec postgres pg_dump -U mobilizon mobilizon > backup.sql

# Restore database
docker compose -f docker/production/docker-compose.yml exec -T postgres psql -U mobilizon mobilizon < backup.sql

# Application backup
docker compose -f docker/production/docker-compose.yml exec mobilizon /bin/mobilizon_ctl backup
```

### Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker compose -f docker/production/docker-compose.yml build
docker compose -f docker/production/docker-compose.yml up -d

# Run migrations
docker compose -f docker/production/docker-compose.yml exec mobilizon /bin/mobilizon_ctl migrate
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Verify database host, port, and credentials
   - Check if database extensions are installed (postgis, pg_trgm, unaccent)
   - Ensure database is accessible from the container

2. **SMTP Configuration Issues**
   - Verify SMTP server and credentials
   - Check TLS settings
   - Test SMTP connection manually

3. **Permission Issues**
   - Fix file permissions for uploads
   ```bash
   docker compose -f docker/production/docker-compose.yml exec mobilizon chown -R nobody:nobody /var/lib/mobilizon/
   ```

4. **Health Check Failures**
   - Check if the application is running: `curl http://localhost:4000/health`
   - Verify database connectivity: `curl http://localhost:4000/health/detailed`
   - Check container logs for errors

### Debug Commands

```bash
# Check environment variables
docker compose -f docker/production/docker-compose.yml exec mobilizon env | grep MOBILIZON

# Access container shell
docker compose -f docker/production/docker-compose.yml exec mobilizon sh

# Check disk space
docker compose -f docker/production/docker-compose.yml exec mobilizon df -h

# Test database connection from container
docker compose -f docker/production/docker-compose.yml exec mobilizon pg_isready -h $MOBILIZON_DATABASE_HOST -p $MOBILIZON_DATABASE_PORT -U $MOBILIZON_DATABASE_USERNAME
```

## Advanced Deployment

### Docker Swarm

```bash
# Deploy to Docker Swarm
docker stack deploy -c docker/production/docker-compose.yml mobilizon
```

### Kubernetes

Create Kubernetes manifests based on the docker/production/docker-compose.yml configuration.

### High Availability

For high availability setups:
- Use external database clusters
- Set up load balancers
- Configure multiple application instances
- Use shared storage for uploads

## Security Considerations

1. **Secrets Management**: Use Docker secrets or external secret management
2. **Network Security**: Restrict container network access
3. **Regular Updates**: Keep containers and dependencies updated
4. **Backup Strategy**: Implement regular backups
5. **Monitoring**: Set up application and infrastructure monitoring