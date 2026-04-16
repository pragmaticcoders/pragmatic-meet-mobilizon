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
