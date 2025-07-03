# Mobilizon Configuration Guide

This document explains how Mobilizon's configuration system works and how to properly configure the application for different environments.

## Configuration Files Overview

### Core Configuration Files

- `config/config.exs` - Base configuration shared by all environments
- `config/dev.exs` - Development environment configuration
- `config/test.exs` - Testing environment configuration
- `config/prod.exs` - Production environment configuration
- `config/docker.exs` - Docker-specific configuration (used as runtime.exs)

### Environment-Specific Loading

The configuration system works as follows:

1. **Base Configuration**: `config.exs` is always loaded
2. **Environment Configuration**: The appropriate environment file is loaded based on `MIX_ENV`
3. **Runtime Configuration**: For Docker deployments, `docker.exs` is copied as `runtime.exs` and loaded at runtime

## Docker Configuration System

### How Docker Configuration Works

When deploying with Docker:

1. **Build Time**: `config/prod.exs` is used during the build process
2. **Runtime**: `config/docker.exs` is copied as `config/runtime.exs` and loaded at runtime
3. **Environment Variables**: All configuration is driven by environment variables

### Configuration Priority

For Docker deployments, the configuration priority is:

1. **Environment Variables** (highest priority)
2. **config/docker.exs** (runtime configuration)
3. **config/prod.exs** (build-time fallbacks)

## Environment Variables

### Required Environment Variables

#### Instance Configuration
```bash
MOBILIZON_INSTANCE_NAME="Your Instance Name"
MOBILIZON_INSTANCE_HOST="your-domain.com"
MOBILIZON_INSTANCE_PORT=4000
MOBILIZON_INSTANCE_EMAIL="noreply@your-domain.com"
MOBILIZON_INSTANCE_SECRET_KEY_BASE="your-secret-key-base"
MOBILIZON_INSTANCE_SECRET_KEY="your-secret-key"
```

#### Database Configuration
```bash
MOBILIZON_DATABASE_USERNAME=mobilizon
MOBILIZON_DATABASE_PASSWORD=your-password
MOBILIZON_DATABASE_DBNAME=mobilizon
MOBILIZON_DATABASE_HOST=postgres  # or your external DB host
MOBILIZON_DATABASE_PORT=5432
MOBILIZON_DATABASE_SSL=false      # true for external DB
```

#### SMTP Configuration
```bash
MOBILIZON_SMTP_SERVER=smtp.gmail.com
MOBILIZON_SMTP_PORT=587
MOBILIZON_SMTP_USERNAME=your-email@gmail.com
MOBILIZON_SMTP_PASSWORD=your-app-password
MOBILIZON_SMTP_TLS=always
MOBILIZON_SMTP_AUTH=always
```

### Optional Environment Variables

#### Instance Features
```bash
MOBILIZON_INSTANCE_REGISTRATIONS_OPEN=true
MOBILIZON_INSTANCE_DEFAULT_LANGUAGE=en
MOBILIZON_INSTANCE_FEDERATING=true
MOBILIZON_INSTANCE_ENABLE_INSTANCE_FEEDS=true
```

#### Logging
```bash
MOBILIZON_LOGLEVEL=info  # error, warning, info, debug
```

#### Geospatial Services
```bash
MOBILIZON_GEOSPATIAL_SERVICE=Nominatim  # Nominatim, GoogleMaps, etc.
```

## Configuration Scenarios

### Scenario 1: Docker with Internal Database (Default)

**Files Used:**
- `config/docker.exs` (as runtime.exs)
- `config/prod.exs` (build-time)

**Environment Variables:**
```bash
MOBILIZON_DATABASE_HOST=postgres
MOBILIZON_DATABASE_SSL=false
```

### Scenario 2: Docker with External Database

**Files Used:**
- `config/docker.exs` (as runtime.exs)
- `config/prod.exs` (build-time)

**Environment Variables:**
```bash
MOBILIZON_DATABASE_HOST=your-external-db-host.com
MOBILIZON_DATABASE_SSL=true
```

### Scenario 3: Non-Docker Production

**Files Used:**
- `config/prod.exs`

**Environment Variables:**
All environment variables are still used, but `prod.exs` provides fallback values.

## Configuration Validation

### Health Check Endpoints

The application provides health check endpoints to verify configuration:

```bash
# Simple health check
curl http://localhost:4000/health

# Detailed health check with database connectivity
curl http://localhost:4000/health/detailed
```

### Configuration Debugging

To debug configuration issues:

```bash
# Check environment variables in container
docker compose exec mobilizon env | grep MOBILIZON

# Check application logs
docker compose logs mobilizon

# Access container shell
docker compose exec mobilizon sh
```

## Common Configuration Issues

### Issue 1: Hardcoded Values Overriding Environment Variables

**Problem:** Configuration files with hardcoded values override environment variables.

**Solution:** Always use `System.get_env/2` with fallback values in configuration files.

### Issue 2: Missing Environment Variables

**Problem:** Application fails to start due to missing required environment variables.

**Solution:** Ensure all required environment variables are set in your `.env` file.

### Issue 3: Database Connection Issues

**Problem:** Application cannot connect to database.

**Solution:** 
1. Verify database credentials
2. Check if database extensions are installed
3. Ensure database is accessible from container

### Issue 4: SMTP Configuration Issues

**Problem:** Emails are not being sent.

**Solution:**
1. Verify SMTP server and credentials
2. Check TLS settings
3. Test SMTP connection manually

## Best Practices

### 1. Use Environment Variables
Always use environment variables for configuration that varies between deployments.

### 2. Provide Sensible Defaults
Use `System.get_env/2` with sensible default values for optional configuration.

### 3. Validate Configuration
Use health check endpoints to validate configuration at runtime.

### 4. Secure Sensitive Data
Never commit sensitive configuration (passwords, keys) to version control.

### 5. Document Configuration
Document all environment variables and their purposes.

## Configuration Templates

### Production Environment Template
See `env.prod.template` for a complete list of all available environment variables with examples.

### Docker Compose Configuration
See `docker/production/docker-compose.yml` for Docker-specific configuration examples. 