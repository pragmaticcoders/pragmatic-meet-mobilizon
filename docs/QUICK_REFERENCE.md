# Quick Reference

## One-Line Commands

### Docker - Automated (Recommended)
```bash
./scripts/run_actor_migration.sh
```

### Docker - Manual
```bash
# Dry-run
docker exec mobilizon_prod bin/mobilizon eval "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"

# Run
docker exec mobilizon_prod bin/mobilizon eval "Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])"
```

### Docker Compose
```bash
docker-compose exec mobilizon bin/mobilizon eval "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"
```

---

## Verification

```bash
# Count users without actors (should be 0)
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT COUNT(*) FROM users 
WHERE default_actor_id IS NULL AND provider IS NULL 
AND confirmed_at IS NOT NULL AND disabled = false;"
```

---

## Backup & Restore

```bash
# Backup
docker exec mobilizon_postgres_prod pg_dump -U mobilizon mobilizon > backup.sql

# Restore
docker exec -i mobilizon_postgres_prod psql -U mobilizon mobilizon < backup.sql
```

---

## Files

| File | Purpose |
|------|---------|
| `docs/ACTOR_FIX_README.md` | Start here |
| `docs/TECHNICAL_DETAILS.md` | Safety & technical analysis |
| `docs/DOCKER_MIGRATION_GUIDE.md` | Complete Docker guide |
| `scripts/run_actor_migration.sh` | Automated script |
| `lib/mix/tasks/mobilizon/users/fix_missing_actors.ex` | Migration code |

---

## What This Fixes

**Problem:** Email/password users can't create groups or edit profile  
**Cause:** Missing actor (profile)  
**Solution:** Creates actors automatically

---

## Safety Checklist

- ✅ Only affects users WITHOUT actors
- ✅ Email/password users only (not OAuth)
- ✅ Uses database transactions (atomic)
- ✅ Dry-run mode available
- ✅ Automatic backups (when using script)

---

**Need more details?** See `docs/ACTOR_FIX_README.md`

