# First Steps in the Project

## 1. Configure Environment Variables

Copy the template file and rename it:

```bash
cp .env.template .env
```

In the `.env` file, update the following variables:

**`POSTGRES_DB`** — any database name you want to use in your local environment

**`MOBILIZON_SMTP_USERNAME`** — your email address

**`MOBILIZON_SMTP_PASSWORD`** — generate an app password:
1. Go to: https://myaccount.google.com/apppasswords
2. Sign in with your Google account (`emil.rusin@pragmaticcoders.com`)
3. In the "App name" field enter e.g. `Mobilizon dev`
4. Click **Create**
5. Copy the generated 16-character password (e.g. `abcd efgh ijkl mnop`)

**`GITHUB_PAT`** — generate a personal access token:
1. Go to: https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. In the "Note" field enter e.g. `Mobilizon dev`
4. Check the `repo` scope
5. Click **Generate token**
6. Copy the generated token

## 2. Start the Application

```bash
make init
```

Then verify the app is running at http://localhost:4000.

## 3. Verify Email Sending

Run the following command and check if the email arrives in your inbox:

```bash
docker compose -f docker/development/docker-compose.yml exec api \
  mix mobilizon.maintenance.test_emails <your_email@gmail.com>
```

## 4. Register a New User

Register a new account using the Pragmatic Meet UI at http://localhost:4000.

## 5. Developing Surveys (Optional)

Survey functionality is backed by the **pragmatic-forms** repository. To develop or rebuild that stack locally as Docker images, build from these Dockerfiles in pragmatic-forms:

- `forms/Dockerfile` → used as the `forms-api` service
- `mobilizon-adapter/Dockerfile` → used as the `mobilizon-adapter` service
- `mobilizon-adapter/frontend/Dockerfile.nginx` → used as the `adapter-nginx` service (serves `remoteEntry.js` and related assets)

From the root of **pragmatic-forms**, build and tag images so their names match the `image:` fields in [`docker/development/docker-compose.yml`](../docker/development/docker-compose.yml) (`forms-api`, `mobilizon-adapter`, `adapter-nginx`):

```bash
cd /path/to/pragmatic-forms

docker build -f forms/Dockerfile -t forms-api .

docker build -f mobilizon-adapter/Dockerfile -t mobilizon-adapter .

docker build -f mobilizon-adapter/frontend/Dockerfile.nginx \
  -t adapter-nginx \
  mobilizon-adapter/frontend
```

Replace these GHCR images with the ones you built: `ghcr.io/pragmaticcoders/forms-api`, `ghcr.io/pragmaticcoders/mobilizon-adapter`, `ghcr.io/pragmaticcoders/adapter-nginx`.

To switch back to published images, use the `ghcr.io/pragmaticcoders/...` lines commented next to each service in that compose file. Survey env vars are in `.env.template`.

For hot-reload from a sibling `pragmatic-forms` checkout, you can use `make start-local-forms` instead (see [`docker/development/docker-compose.local-forms.yml`](../docker/development/docker-compose.local-forms.yml)).
