# Pragmatic Meet — development

Fork of Mobilizon for local development: Docker (default) or native stack — start in [Quick start](#quick-start).

## Table of contents

- [Quick start](#quick-start)
- [Docker development](#docker-development)
- [Native development](#native-development)
- [Database](#database-management)
- [Environment variables](#environment-variables)
- [Useful commands](#useful-commands)
- [Troubleshooting](#troubleshooting)

## Quick start

Use the **repository root** (`Makefile` and `.env` sit next to each other; do not `cd docker/development` for the default flow).

### What you need

**Docker (recommended):** Docker & Compose, Git. ~4 GB RAM, ~5 GB disk.

**GHCR** (pull default **forms** images): create a GitHub [personal access token](https://github.com/settings/tokens) (classic is enough) with the **`read:packages`** scope. Run `docker login ghcr.io`; if the CLI asks for a **sign-in method**, choose **login with token** (not browser / SSO). Enter your **GitHub username** and use the **PAT** as the password. Non-interactive: `echo '<PAT>' | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin`.

**Native instead:** PostgreSQL 15+ with PostGIS, Elixir 1.15+, Erlang/OTP 26+, Node.js 18+, npm, Git.

**OS:** Linux, macOS, or Windows with WSL2.

### Run with Docker

1. Clone the repo and `cd` into it.
2. `cp .env.template .env` and fill at least **`POSTGRES_DB`**, **`MOBILIZON_SMTP_USERNAME`** / **`MOBILIZON_SMTP_PASSWORD`**, **`GITHUB_PAT`** (classic token, **`repo`** scope). Survey-related variables: [`.env.template`](.env.template).
3. `make init` — builds and starts the dev stack (`docker/development/docker-compose.yml` + `.env`).
4. App: http://localhost:4000 · GraphQL: http://localhost:4000/api/graphql · **Swoosh mail preview** (dev/e2e only): http://localhost:4000/sent_emails — shows captured mail only with **Local** adapter (no `MOBILIZON_SMTP_SERVER`; see `config/dev.exs`). Docker dev with SMTP: use your inbox or step 5.
5. (Optional) Send a test message:  
   `docker compose --env-file .env -f docker/development/docker-compose.yml exec api mix mobilizon.maintenance.test_emails you@example.com`
6. Register via the UI, or use mix tasks from [GUIDES.md](GUIDES.md).

**Surveys — `FORMS_SERVICE_API_KEY` (once per fresh `forms-db` volume):** the Forms service expects a **client** key (not `FORMS_ADMIN_API_KEY`). After volume wipe / first run, register the adapter and paste the returned **`api_key`** into `.env`.

1. Ensure **`FORMS_ADMIN_API_KEY`** is set in `.env` (see [`.env.template`](.env.template)).
2. Create the client (from **repo root**, stack already up — `make start` / `make init` / `make start-local-forms`):

   ```bash
   docker exec pragmatic_forms_adapter wget -qO- \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $(grep FORMS_ADMIN_API_KEY .env | cut -d= -f2)" \
     --post-data '{"name": "mobilizon-adapter"}' \
     http://forms-api:3000/clients
   ```

3. Copy **`api_key`** from the JSON → set **`FORMS_SERVICE_API_KEY=<that value>`** in `.env`.
4. Restart the adapter so it reloads env:

   ```bash
   # Default stack (e.g. make init / make start)
   docker compose --env-file .env -f docker/development/docker-compose.yml \
     up -d --force-recreate mobilizon-adapter

   # If you use make start-local-forms, add the overlay file:
   docker compose --env-file .env \
     -f docker/development/docker-compose.yml \
     -f docker/development/docker-compose.local-forms.yml \
     up -d --force-recreate mobilizon-adapter
   ```

   Repeat from step 2 if you recreate the `forms-db` volume. More context: [docker/README — Troubleshooting](docker/README.md#troubleshooting).

**Developing the survey stack in source:** [Developing surveys](#developing-surveys-pragmatic-forms).

Published forms images use the tag from the repo-root file **`forms-image-tag`** (see **`Makefile`**).

### Run natively

```bash
git clone <repository-url>
cd pragmatic-meet-mobilizon
mix deps.get && npm install && mix ecto.setup
# Terminal 1: mix phx.server  |  Terminal 2: npm run dev
```

Install Postgres, env samples, and tips: [Native development](#native-development).

## Docker development

Day-to-day commands and survey builds after you are up from [Quick start](#quick-start).

### Make targets

```bash
make init      # build + start (first time or after clone)
make setup     # deps + create DB + migrate (without full init)
make start     # start services
make stop      # stop
make logs      # follow logs
make migrate   # run migrations
make test      # tests
make format    # Elixir + frontend format / credo
make start-local-forms   # sibling pragmatic-forms checkout: build forms stack from source
make pull-forms          # refresh GHCR forms images (see forms-image-tag)
```

### Services and ports

| Service | Port | Purpose |
|---------|------|---------|
| API (Phoenix) | 4000 | Web + API |
| Vite | 5173 | Frontend dev / hot reload |
| PostgreSQL | 5432 | DB (in Compose network) |

### Developing surveys (pragmatic-forms)

Survey stack = **pragmatic-forms** repository (images) + env from [`.env.template`](.env.template). Compose service names and manual `docker build` commands for local images are documented in **pragmatic-forms**: [`docs/docker.md`](https://github.com/pragmaticcoders/pragmatic-forms/blob/main/docs/docker.md) (same layout as [`docker/development/docker-compose.yml`](docker/development/docker-compose.yml)).

**Images:** by default [`docker/development/docker-compose.yml`](docker/development/docker-compose.yml) uses **GHCR** images (`ghcr.io/pragmaticcoders/forms-api`, `mobilizon-adapter`, `adapter-nginx`). The tag for pulls follows repo-root **`forms-image-tag`** (see [Quick start](#quick-start)). Use **`make pull-forms`** after changing that file. To run from source instead of GHCR, use **`make start-local-forms`** when **pragmatic-forms** is a **sibling** directory; the overlay builds the same Compose service names locally. If you customize Compose or build images by hand, set each service’s `image:` to either those GHCR names or your local tags (`forms-api`, `mobilizon-adapter`, `adapter-nginx`) so names stay consistent with the stack.

## Native development

### Database setup

```bash
# Install PostgreSQL with PostGIS (example for macOS)
brew install postgresql@15 postgis

# Start PostgreSQL
brew services start postgresql@15

# Create database and user
createuser -P mobilizon  # Password: mobilizon
createdb -O mobilizon mobilizon_dev
```

### Backend setup

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

### Frontend setup

```bash
# Install Node.js dependencies
npm install

# Build static assets (for development)
npm run build:pictures

# Start Vite development server (optional, for hot reloading)
npm run dev
```

### Environment (native)

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

### Instance restrictions

| Variable | Default | Description |
|----------|---------|-------------|
| `MOBILIZON_RESTRICTIONS_ALLOW_MODERATOR_ACTIVITY_FOR_PENDING_GROUPS` | unset / `true` | When `true` (default), group creators, moderators, and administrators can manage members and create content while the group awaits instance approval. Events attributed to that group are stored with `pending_group_approval`: they stay off public listings, search, federation, and “new event” notifications until an administrator approves the group; approval then releases them (unless the event is a draft). Rejected or suspended groups do not auto-release held events. Set to `false` to disable this workflow. Changing this value requires an application restart (and config cache refresh if applicable). |

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

## Next steps

- GraphQL: http://localhost:4000/api/graphql  
- Architecture: [docs/dev.md](docs/dev.md)  
- Contributing: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)  
- Upstream docs: https://docs.joinmobilizon.org  
- Production: [docs/PRODUCTION_DEPLOYMENT.md](docs/PRODUCTION_DEPLOYMENT.md)
