# Pragmatic Meet — development

Fork of Mobilizon for local development: Docker (default) or native stack — start in [Quick start](#quick-start).

## Table of contents

- [Quick start](#quick-start)
- [Docker development](#docker-development)
- [Native development](#native-development)
- [Dev Container](#dev-container)
- [User Management](#user-management)
- [Testing & Quality](#testing--quality)
- [Database Management](#database-management)
- [Operations & Maintenance](#operations--maintenance)
- [Environment variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

---

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
6. Register via the UI, or use mix tasks from [User Management](#user-management).

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

---

## Docker development

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

**Using local containers:**
If you want to use local versions of the survey stack containers (e.g., to test changes not yet pushed to GHCR):
1. **Build them locally:** Go to your local **pragmatic-forms** checkout and build the images from their respective Dockerfiles (refer to their documentation for specific commands).
2. **Update Image Tags:** In `docker/development/docker-compose.yml`, update the `image:` lines for `mobilizon-adapter`, `forms-api`, and `adapter-nginx` to match your local tags (e.g., `image: mobilizon-adapter:local`).
3. **Automated Alternative:** Use **`make start-local-forms`** from the Mobilizon root. This requires **pragmatic-forms** to be a **sibling directory**. It uses a Compose overlay (`docker/development/docker-compose.local-forms.yml`) to automatically build those services from source and mount local code for hot-reloading.

---

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

---

## Dev Container

For a fully isolated environment using VS Code Dev Containers:

1. Open the project in VS Code.
2. Click "Reopen in Container" when prompted (or use the Command Palette).
3. Once the container is ready, run the startup script:
   ```bash
   ./scripts/dev-start.sh
   ```
4. To stop the application:
   ```bash
   ./scripts/dev-stop.sh
   ```

---

## User Management

Manage users via Mix tasks. For Docker, prefix commands with `docker compose exec api`.

### Create a new user

```bash
# Docker
docker compose exec api mix mobilizon.users.new email@example.com --password YourPassword123 --admin

# Native
mix mobilizon.users.new email@example.com --password YourPassword123 --admin
```

**Options:**
- `--admin`: Make the user an administrator
- `--moderator`: Make the user a moderator
- `--profile_username`: Create a profile with this username
- `--profile_display_name`: Set the profile display name

### Modify an existing user

```bash
# Promote to admin
mix mobilizon.users.modify email@example.com --admin

# Change password
mix mobilizon.users.modify email@example.com --password NewPassword123

# Disable user
mix mobilizon.users.modify email@example.com --disable
```

---

## Testing & Quality

### Running Tests

```bash
# Backend (Elixir)
make test      # Docker
mix test       # Native

# Frontend (Vue/Vitest)
npm run test
```

### Linting & Formatting

```bash
# Complete check (Docker)
make format

# Individual commands (Native)
mix format         # Format Elixir code
mix credo --strict # Elixir static analysis
npm run format     # Format frontend code
npm run lint       # Lint frontend code
```

---

## Database Management

### Operations

| Task | Docker Command | Native Command |
|------|----------------|----------------|
| **Reset DB** | `make setup` | `mix ecto.reset` |
| **Migrate** | `make migrate` | `mix ecto.migrate` |
| **Rollback** | `docker compose exec api mix ecto.rollback` | `mix ecto.rollback` |
| **Seed Data** | `docker compose exec api mix run priv/repo/seeds.exs` | `mix run priv/repo/seeds.exs` |

### Database Access

```bash
# Docker setup
docker compose -f docker/development/docker-compose.yml exec postgres psql -U mobilizon mobilizon

# Native setup
psql -h localhost -U mobilizon mobilizon_dev
```

---

## Operations & Maintenance

### Remote Server Access (Production/Staging)

To perform maintenance on remote instances:

1. **SSH into the server**:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ssh root@<server_ip> -A
   ```

2. **Access Database via Docker**:
   ```bash
   docker exec -it <postgis_container_id> psql -h postgres -U mobilizon
   ```

3. **Promote user to Administrator (via SQL)**:
   ```sql
   UPDATE users SET role = 'administrator' WHERE email = 'email@example.com';
   ```

### Manual Data Cleanup

If you need to wipe user data while keeping the schema:
1. Run the cleanup script: `bash scripts/database_cleanup.sh`
2. Apply the generated SQL: `psql -h localhost -U mobilizon mobilizon_dev -f final_cleanup_generated.sql`

---

## Environment variables

Core variables in `.env`. See [`.env.template`](.env.template) for full documentation.

| Variable | Default | Description |
|----------|---------|-------------|
| `MOBILIZON_INSTANCE_NAME` | "Mobilizon" | Instance display name |
| `MOBILIZON_INSTANCE_HOST` | "localhost" | Domain name |
| `MOBILIZON_INSTANCE_PORT` | "4000" | Port number |
| `MOBILIZON_RESTRICTIONS_ALLOW_MODERATOR_ACTIVITY_FOR_PENDING_GROUPS` | `true` | Workflow for group approval |

---

## Troubleshooting

### Common Issues

**Port Already in Use (4000 or 5173)**
```bash
lsof -ti:4000 | xargs kill -9
```

**Permission Issues (Docker)**
```bash
sudo chown -R $USER:$USER .
docker compose -f docker/development/docker-compose.yml build --no-cache
```

**Frontend HMR Not Working**
Ensure `VITE_HOST=localhost` (Native) or `VITE_HOST=0.0.0.0` (Docker) is set correctly in `.env`.

---

## Next steps

- GraphQL: http://localhost:4000/api/graphql  
- Architecture: [docs/dev.md](docs/dev.md)  
- Contributing: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)  
- Upstream docs: https://docs.joinmobilizon.org  
- Production: [docs/PRODUCTION_DEPLOYMENT.md](docs/PRODUCTION_DEPLOYMENT.md)
