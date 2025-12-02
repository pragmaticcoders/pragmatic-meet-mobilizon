# Docker Migration Guide

Complete guide for running the actor fix migration in Docker.

---

## 🚀 Quick Start

```bash
# Easiest way - automated script
./scripts/run_actor_migration.sh
```

This handles everything: backup, dry-run, confirmation, migration, verification.

---

## Manual Docker Commands

### Step 1: Backup Database

```bash
docker exec mobilizon_postgres_prod pg_dump -U mobilizon mobilizon > \
  backup_$(date +%Y%m%d_%H%M%S).sql
```

### Step 2: Dry-Run (Preview)

```bash
docker exec mobilizon_prod bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"
```

**Expected output:**
```
🔍 Running in DRY-RUN mode - no changes will be made

Found 3 user(s) without default actors

Would create actor 'ewelinlech' for: ewelina.lech@example.com
Would create actor 'johnsmith' for: john.smith@example.com

============================================================
DRY-RUN Summary:
  - Would create actors for: 2 user(s)
  - Would fail for: 0 user(s)
```

### Step 3: Run Migration

```bash
docker exec mobilizon_prod bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])"
```

### Step 4: Verify

```bash
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT COUNT(*) FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false;"
```

Should return **0**.

---

## Docker Compose

If using `docker-compose`:

```bash
cd docker/production

# Dry-run
docker-compose exec mobilizon bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"

# Real run
docker-compose exec mobilizon bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])"
```

---

## Container Name Customization

If your containers have different names:

```bash
# Find your container names
docker ps | grep mobilizon

# Set environment variables
export MOBILIZON_CONTAINER=your_mobilizon_container
export POSTGRES_CONTAINER=your_postgres_container

# Run script
./scripts/run_actor_migration.sh
```

Or manually:

```bash
docker exec YOUR_CONTAINER_NAME bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"
```

---

## Troubleshooting

### Issue: "Module not found"

**Cause:** Script not in Docker image yet.

**Solution:**
```bash
# Rebuild image
docker build -t your-registry/mobilizon:latest -f docker/production/Dockerfile .
docker push your-registry/mobilizon:latest

# Update containers
docker-compose pull
docker-compose up -d
```

### Issue: "Container not running"

**Check containers:**
```bash
docker ps
```

**Start if needed:**
```bash
docker-compose up -d
```

### Issue: "Database connection error"

**Check database:**
```bash
docker logs mobilizon_postgres_prod

# Verify database is responding
docker exec mobilizon_postgres_prod psql -U mobilizon -c "\l"
```

### Issue: "Permission denied"

**Make script executable:**
```bash
chmod +x scripts/run_actor_migration.sh
```

---

## Monitoring During Migration

### Watch Application Logs

```bash
docker logs -f mobilizon_prod
```

### Check Database Activity

```bash
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT query, state, query_start 
FROM pg_stat_activity 
WHERE datname = 'mobilizon' AND state != 'idle';"
```

### Monitor Resources

```bash
docker stats mobilizon_prod mobilizon_postgres_prod
```

---

## Rollback

If you need to rollback:

```bash
# Restore from backup
docker exec -i mobilizon_postgres_prod psql -U mobilizon mobilizon < \
  backup_YYYYMMDD_HHMMSS.sql

# Restart services
docker restart mobilizon_prod
```

---

## Multi-Environment Setup

### Development

```bash
docker exec mobilizon_dev bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"
```

### Staging

```bash
docker exec mobilizon_staging bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])"
```

### Production

```bash
# ALWAYS dry-run first in production!
./scripts/run_actor_migration.sh
```

---

## Complete Workflow Script

Save as `migrate.sh`:

```bash
#!/bin/bash
set -e

# 1. Backup
echo "Creating backup..."
docker exec mobilizon_postgres_prod pg_dump -U mobilizon mobilizon > \
  backup_$(date +%Y%m%d).sql

# 2. Dry-run
echo "Running dry-run..."
docker exec mobilizon_prod bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"

# 3. Confirm
read -p "Proceed? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Cancelled"
  exit 1
fi

# 4. Run
echo "Running migration..."
docker exec mobilizon_prod bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])"

# 5. Verify
echo "Verifying..."
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT COUNT(*) FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false;"

echo "Done!"
```

Run: `chmod +x migrate.sh && ./migrate.sh`

---

## Verification Queries

### Check Affected Users Before Migration

```bash
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT email, created_at
FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false
ORDER BY created_at DESC;"
```

### Check Created Actors After Migration

```bash
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT u.email, a.preferred_username, a.inserted_at
FROM users u
JOIN actors a ON u.default_actor_id = a.id
WHERE u.provider IS NULL
ORDER BY a.inserted_at DESC
LIMIT 10;"
```

---

## Post-Migration

### User Testing Steps

1. **Log out and log in** - Refreshes session
2. **Try to create a group** - Should work now
3. **Check profile** - Username should be populated
4. **Edit profile** - Username field should show value

### System Health Checks

```bash
# Check application health
docker exec mobilizon_prod curl -f http://localhost:4000/health

# Check for errors in logs
docker logs mobilizon_prod --since 1h | grep -i error

# Verify all services running
docker ps --filter "name=mobilizon"
```

---

## Support

- **Safety analysis:** See `docs/TECHNICAL_DETAILS.md`
- **Overview:** See `docs/ACTOR_FIX_README.md`
- **Quick commands:** See `docs/QUICK_REFERENCE.md`

---

**Last Updated:** December 1, 2025  
**Tested:** Docker Compose production environment

