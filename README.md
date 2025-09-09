# Mobilizon Development Setup Guide

A comprehensive guide for setting up and running Mobilizon locally for development purposes.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development Setup Options](#development-setup-options)
  - [Option 1: Docker Development (Recommended)](#option-1-docker-development-recommended)
  - [Option 2: Native Development](#option-2-native-development)
- [Database Management](#database-management)
- [Environment Variables](#environment-variables)
- [Useful Commands](#useful-commands)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Software

- **Docker & Docker Compose** (for Docker setup)
- **PostgreSQL 15+** with PostGIS extension (for native setup)
- **Elixir 1.15+** and **Erlang/OTP 26+** (for native setup)
- **Node.js 18+** and **npm** (for frontend)
- **Git**

### System Requirements

- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 5GB free space
- **OS**: Linux, macOS, or Windows with WSL2

## 🚀 Quick Start

### Docker Development (Fastest)

```bash
# 1. Clone and enter the repository
git clone <repository-url>
cd pragmatic-meet-mobilizon

# 2. Start everything with one command
make init

# 3. Access your local instance
# Frontend: http://localhost:4000
# GraphQL API: http://localhost:4000/api/graphql
```

### Native Development

```bash
# 1. Clone repository
git clone <repository-url>
cd pragmatic-meet-mobilizon

# 2. Install dependencies
mix deps.get
npm install

# 3. Setup database
mix ecto.setup

# 4. Start development servers
# Terminal 1: Backend
mix phx.server

# Terminal 2: Frontend (in another terminal)
npm run dev
```

## 🐳 Development Setup Options

### Option 1: Docker Development (Recommended)

Docker provides the most consistent development environment across different systems.

#### Initial Setup

```bash
# Start the complete development environment
make init

# Or step by step:
make setup    # Install dependencies and setup database
make start    # Start services
```

#### Available Make Commands

```bash
make init      # Complete setup and start
make setup     # Install deps, create & migrate database
make start     # Start all services
make stop      # Stop all services
make logs      # View container logs
make migrate   # Run database migrations
make test      # Run test suite
make format    # Format code (Elixir + frontend)
```

#### Docker Services

| Service | Port | Purpose |
|---------|------|---------|
| API (Phoenix) | 4000 | Backend API and web interface |
| Vite Dev Server | 5173 | Frontend hot reloading |
| PostgreSQL | 5432 | Database (internal to containers) |

#### Accessing the Application

- **Main Application**: http://localhost:4000
- **GraphQL Playground**: http://localhost:4000/api/graphql
- **Mailbox (Local emails)**: http://localhost:4000/dev/mailbox

### Option 2: Native Development

For developers who prefer running services directly on their system.

#### Database Setup

```bash
# Install PostgreSQL with PostGIS (example for macOS)
brew install postgresql@15 postgis

# Start PostgreSQL
brew services start postgresql@15

# Create database and user
createuser -P mobilizon  # Password: mobilizon
createdb -O mobilizon mobilizon_dev
```

#### Backend Setup

```bash
# Install Elixir dependencies
mix deps.get

# Setup database
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

# Start Phoenix server
mix phx.server
```

#### Frontend Setup

```bash
# Install Node.js dependencies
npm install

# Build static assets (for development)
npm run build:pictures

# Start Vite development server (optional, for hot reloading)
npm run dev
```

#### Environment Configuration

Create a `.env` file in the project root (optional):

```bash
# Database
MOBILIZON_DATABASE_USERNAME=mobilizon
MOBILIZON_DATABASE_PASSWORD=mobilizon
MOBILIZON_DATABASE_DBNAME=mobilizon_dev
MOBILIZON_DATABASE_HOST=localhost
MOBILIZON_DATABASE_PORT=5432

# Instance
MOBILIZON_INSTANCE_NAME="My Dev Instance"
MOBILIZON_INSTANCE_HOST=localhost
MOBILIZON_INSTANCE_HOST_PORT=4000
MOBILIZON_INSTANCE_EMAIL=dev@localhost
MOBILIZON_INSTANCE_REGISTRATIONS_OPEN=true

# Security (for development only)
MOBILIZON_INSTANCE_SECRET_KEY_BASE=changethis
MOBILIZON_INSTANCE_SECRET_KEY=changethis
```

## 🗄️ Database Management

### Database Operations

#### Reset Database (Complete Cleanup)

```bash
# Docker setup
docker compose -f docker/development/docker-compose.yml run --rm api mix ecto.reset

# Native setup
mix ecto.reset
```

#### Manual Database Cleanup

For cleaning up user data while preserving schema:

```bash
# Using the provided cleanup script (Docker)
docker compose -f docker/development/docker-compose.yml run --rm api bash -c "cd scripts && bash database_cleanup.sh"

# Native setup
cd scripts
bash database_cleanup.sh
psql -h localhost -U mobilizon mobilizon_dev -f final_cleanup_generated.sql
```

#### Migration Commands

```bash
# Run pending migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Check migration status
mix ecto.migrations
```

#### Seeding Test Data

```bash
# Add sample data for development
mix run priv/repo/seeds.exs
```

### Database Access

```bash
# Docker setup
docker compose -f docker/development/docker-compose.yml exec postgres psql -U mobilizon mobilizon

# Native setup
psql -h localhost -U mobilizon mobilizon_dev
```

## 🔧 Environment Variables

### Core Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MOBILIZON_INSTANCE_NAME` | "Mobilizon" | Instance display name |
| `MOBILIZON_INSTANCE_HOST` | "localhost" | Domain name |
| `MOBILIZON_INSTANCE_HOST_PORT` | "4000" | Port number |
| `MOBILIZON_INSTANCE_EMAIL` | - | System email address |
| `MOBILIZON_INSTANCE_REGISTRATIONS_OPEN` | "true" | Allow new registrations |

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MOBILIZON_DATABASE_USERNAME` | "mobilizon" | Database user |
| `MOBILIZON_DATABASE_PASSWORD` | "mobilizon" | Database password |
| `MOBILIZON_DATABASE_DBNAME` | "mobilizon_dev" | Database name |
| `MOBILIZON_DATABASE_HOST` | "localhost" | Database host |
| `MOBILIZON_DATABASE_PORT` | "5432" | Database port |

### Security (Development Only)

| Variable | Default | Description |
|----------|---------|-------------|
| `MOBILIZON_INSTANCE_SECRET_KEY_BASE` | "changethis" | Phoenix secret key |
| `MOBILIZON_INSTANCE_SECRET_KEY` | "changethis" | Guardian JWT secret |

## 📝 Useful Commands

### Development

```bash
# Format code
mix format                    # Elixir code
npm run format               # Frontend code

# Linting
mix credo                    # Elixir linting
npm run lint                 # Frontend linting

# Testing
mix test                     # Backend tests
npm test                     # Frontend tests
npm run coverage             # Test coverage
```

### Frontend Development

```bash
npm run dev                  # Start Vite dev server
npm run build               # Build for production
npm run preview             # Preview production build
npm run story:dev           # Start Storybook
```

### Database

```bash
mix ecto.create             # Create database
mix ecto.drop               # Drop database
mix ecto.migrate            # Run migrations
mix ecto.rollback           # Rollback migrations
mix ecto.reset              # Drop, create, migrate, seed
```

### Utilities

```bash
# Generate GraphQL schema
mix absinthe.schema.json --schema Mobilizon.GraphQL.Schema

# Interactive Elixir shell
iex -S mix

# Check dependencies
mix deps.tree
mix hex.outdated
```

## 🔍 Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Kill processes on port 4000
lsof -ti:4000 | xargs kill -9

# Kill processes on port 5173 (Vite)
lsof -ti:5173 | xargs kill -9
```

#### Database Connection Issues

```bash
# Check PostgreSQL status
pg_isready -h localhost -p 5432

# Restart PostgreSQL (macOS)
brew services restart postgresql@15

# Check database exists
psql -h localhost -U mobilizon -l
```

#### Permission Issues (Docker)

```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Rebuild containers
docker compose -f docker/development/docker-compose.yml build --no-cache
```

#### Frontend Issues

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### Mix Dependencies Issues

```bash
# Clean and recompile
mix deps.clean --all
mix deps.get
mix compile
```

### Getting Help

1. **Check logs**:
   ```bash
   # Docker
   make logs
   
   # Native
   tail -f _build/dev/lib/mobilizon/ebin/mobilizon.log
   ```

2. **Database state**:
   ```bash
   mix ecto.migrations
   ```

3. **Process status**:
   ```bash
   # Check what's running on ports
   lsof -i :4000
   lsof -i :5173
   ```

### Performance Tips

- **Use Docker volumes**: Don't mount the entire project if possible
- **Increase memory**: Elixir compilation can be memory-intensive
- **Use SSD**: Database and compilation benefit from fast storage
- **Disable unnecessary services**: Stop other databases/servers

## 🎯 Next Steps

After setup, you can:

1. **Explore the API**: Visit http://localhost:4000/api/graphql
2. **Create test events**: Use the web interface
3. **Review the codebase**: Check `/docs/dev.md` for architecture overview
4. **Read contributing guidelines**: See `CONTRIBUTING.md`

---

## 📚 Additional Resources

- **Main Documentation**: https://docs.joinmobilizon.org
- **Contributing Guide**: `CONTRIBUTING.md`
- **Architecture Overview**: `docs/dev.md`
- **Production Deployment**: `docs/PRODUCTION_DEPLOYMENT.md`

---

**Happy coding! 🎉**
