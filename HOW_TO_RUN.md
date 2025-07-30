# How to Run Mobilizon Locally

This guide covers multiple ways to run Mobilizon locally for development purposes.

## Overview

Mobilizon is a federated event organization platform built with:
- **Backend**: Elixir/Phoenix with GraphQL API
- **Frontend**: Vue.js 3 with Vite
- **Database**: PostgreSQL with PostGIS extensions

## Prerequisites

- Git (to clone the repository)
- One of the following environments:
  - Docker and Docker Compose (recommended)
  - Native development environment with Elixir, Node.js, and PostgreSQL

## Method 1: Docker Setup (Recommended)

### 1. Install Docker

If Docker is not installed on your system:

```bash
# Download and install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group (requires logout/login to take effect)
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. Setup Environment

```bash
# Copy environment template
cp env.prod.template .env

# The default values in .env should work for development
# You can edit .env if needed, but defaults are fine for local development
```

### 3. Run with Docker

```bash
# Complete setup (installs dependencies, creates database, runs migrations)
make setup

# Start the application
make start

# View logs (optional)
make logs
```

### 4. Access the Application

- **Frontend (UI)**: http://localhost:5173
- **Backend API**: http://localhost:4000
- **GraphQL Playground**: http://localhost:4000/api/graphql

### 5. Stop the Application

```bash
make stop
```

### Available Make Commands

```bash
make init     # Complete initialization (setup + start)
make setup    # Install dependencies and setup database
make start    # Start the services
make stop     # Stop the services
make logs     # View application logs
make migrate  # Run database migrations
make test     # Run tests
make format   # Format code
```

## Method 2: Native Setup (Devcontainer/Manual)

If you're running in a devcontainer or prefer native development:

### Prerequisites

- Elixir 1.15+
- Node.js 20+
- PostgreSQL 15+ with PostGIS extension
- npm or yarn

### 1. Verify Prerequisites

```bash
# Check if tools are available
which elixir && which mix && which node && which npm
psql --version
```

### 2. Setup Database

```bash
# Create database (adjust credentials as needed)
PGPASSWORD=postgres psql -h localhost -U postgres -c "CREATE DATABASE mobilizon;"

# Create required extensions
PGPASSWORD=postgres psql -h localhost -U postgres -d mobilizon -c "
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
  CREATE EXTENSION IF NOT EXISTS unaccent;
"

# Verify extensions
PGPASSWORD=postgres psql -h localhost -U postgres -d mobilizon -c "\\dx"
```

### 3. Install Dependencies

```bash
# Set environment variables
export MIX_ENV=dev
export MOBILIZON_DATABASE_HOST=localhost
export MOBILIZON_DATABASE_USERNAME=postgres
export MOBILIZON_DATABASE_PASSWORD=postgres
export MOBILIZON_DATABASE_DBNAME=mobilizon

# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies
npm ci

# Build picture assets
npm run build:pictures
```

### 4. Run Database Migrations

```bash
# Run migrations
mix ecto.migrate
```

### 5. Start the Servers

You'll need to run these in separate terminals or in the background:

#### Terminal 1: Backend (Phoenix Server)
```bash
export MIX_ENV=dev
export MOBILIZON_DATABASE_HOST=localhost
export MOBILIZON_DATABASE_USERNAME=postgres
export MOBILIZON_DATABASE_PASSWORD=postgres
export MOBILIZON_DATABASE_DBNAME=mobilizon
export MOBILIZON_INSTANCE_NAME="My Mobilizon Instance"
export MOBILIZON_INSTANCE_HOST=localhost
export MOBILIZON_INSTANCE_PORT=4000
export MOBILIZON_INSTANCE_EMAIL=noreply@mobilizon.me
export MOBILIZON_INSTANCE_REGISTRATIONS_OPEN=true
export MOBILIZON_INSTANCE_SECRET_KEY_BASE=changethis
export MOBILIZON_INSTANCE_SECRET_KEY=changethis

mix phx.server
```

#### Terminal 2: Frontend (Vite Dev Server)
```bash
npm run dev
```

### 6. Verify Setup

Check that both servers are running:
```bash
# Check if ports are listening
netstat -tlnp | grep -E ":(4000|5173)"
# or
ss -tlnp | grep -E ":(4000|5173)"
```

You should see:
- Port 4000: Phoenix server (backend)
- Port 5173: Vite dev server (frontend)

### 7. Access the Application

- **Frontend (UI)**: http://localhost:5173
- **Backend API**: http://localhost:4000
- **GraphQL Playground**: http://localhost:4000/api/graphql

## Environment Variables

Key environment variables for development:

```bash
# Database
MOBILIZON_DATABASE_HOST=localhost
MOBILIZON_DATABASE_USERNAME=postgres
MOBILIZON_DATABASE_PASSWORD=postgres
MOBILIZON_DATABASE_DBNAME=mobilizon

# Instance configuration
MOBILIZON_INSTANCE_NAME="My Mobilizon Instance"
MOBILIZON_INSTANCE_HOST=localhost
MOBILIZON_INSTANCE_PORT=4000
MOBILIZON_INSTANCE_EMAIL=noreply@mobilizon.me
MOBILIZON_INSTANCE_REGISTRATIONS_OPEN=true

# Security (change these in production!)
MOBILIZON_INSTANCE_SECRET_KEY_BASE=changethis
MOBILIZON_INSTANCE_SECRET_KEY=changethis
```

## Troubleshooting

### Docker Issues

1. **"docker: No such file or directory"**
   - Install Docker using the instructions above
   - Make sure Docker service is running

2. **Permission denied errors**
   - Add your user to the docker group: `sudo usermod -aG docker $USER`
   - Log out and log back in

### Native Setup Issues

1. **PostgreSQL connection failed**
   - Check if PostgreSQL is running: `pg_isready`
   - Verify credentials and database exists
   - Check if PostGIS extensions are installed

2. **Port already in use**
   - Kill existing processes: `pkill -f "mix phx.server"` or `pkill -f "npm run dev"`
   - Check what's using the port: `lsof -i :4000` or `lsof -i :5173`

3. **Mix/Elixir errors**
   - Ensure you're in the project directory
   - Verify Elixir version: `elixir --version`
   - Clean dependencies: `mix deps.clean --all && mix deps.get`

### General Issues

1. **Frontend not loading**
   - Check if Vite dev server is running on port 5173
   - Look for errors in the browser console
   - Ensure backend is accessible at port 4000

2. **Database migration errors**
   - Check PostgreSQL logs
   - Ensure database exists and extensions are installed
   - Verify database credentials

## First Time Setup

1. **Access the UI**: Navigate to http://localhost:5173
2. **Create Admin Account**: Register as the first user (you'll automatically become an admin)
3. **Configure Instance**: Use the admin panel to configure your instance settings
4. **Create Content**: Start creating events, groups, and explore the platform

## Development Workflow

- **Frontend changes**: Automatically reloaded by Vite
- **Backend changes**: Automatically reloaded by Phoenix
- **Database changes**: Run `mix ecto.migrate` after creating new migrations
- **Dependencies**: Run `mix deps.get` and `npm ci` when dependencies change

## Stopping the Application

### Docker
```bash
make stop
```

### Native
```bash
# Kill background processes
pkill -f "mix phx.server"
pkill -f "npm run dev"
```

## Additional Resources

- [Mobilizon Documentation](https://docs.joinmobilizon.org)
- [Contributing Guide](CONTRIBUTING.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Production Deployment](docs/PRODUCTION_DEPLOYMENT.md)