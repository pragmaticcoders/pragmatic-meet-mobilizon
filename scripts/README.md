# Mobilizon Development & Maintenance Scripts

This directory contains scripts to help you develop, maintain, and operate your Mobilizon instance.

## 🚀 Dev Container Scripts

### `dev-start.sh` - Complete Startup
**Purpose**: Starts the entire Mobilizon development environment inside a dev container.
**Usage**: `./scripts/dev-start.sh`

### `dev-stop.sh` - Clean Shutdown
**Purpose**: Safely stops all development services.
**Usage**: `./scripts/dev-stop.sh`

### `dev-status.sh` - Service Health Check
**Purpose**: Provides status information about all running services.
**Usage**: `./scripts/dev-status.sh`

---

## 🛠️ Maintenance Scripts

### `run_actor_migration.sh` - Fix Missing User Profiles
**Purpose**: Fixes an issue where email/password users might not have an associated actor (profile) created automatically.
**Usage**:
```bash
./scripts/run_actor_migration.sh
```
This script handles database backup, dry-run preview, and the actual migration.

### `database_cleanup.sh` - Reset User Data
**Purpose**: Generates SQL to wipe user-generated data while preserving the database schema.
**Usage**:
```bash
bash scripts/database_cleanup.sh
```
Follow the instructions in the Master README for applying the generated SQL.

---

## 🧪 Testing Scripts

### `run-e2e-docker.sh` - End-to-End Tests
**Purpose**: Runs the Playwright E2E test suite inside Docker containers.
**Usage**:
```bash
./scripts/run-e2e-docker.sh
```

---

## 📦 Build & Release

### `build/pictures.sh`
**Purpose**: Generates responsive versions of pictures for the application.
**Used by**: `npm run build:pictures`.

### `release.sh`
**Purpose**: Automates the creation and pushing of Git tags for new releases.

---

## 🚨 Troubleshooting
If a script fails to run, ensure it has execution permissions:
```bash
chmod +x scripts/*.sh
```
