# Actor Fix for Missing User Profiles

## Quick Summary

**Problem:** Users registered with email/password can't create groups or edit their profile.  
**Cause:** They don't have an actor (profile) created automatically.  
**Solution:** Code fix + migration script for existing users.

---

## Files in This Fix

| File | Purpose |
|------|---------|
| `lib/graphql/resolvers/user.ex` | Code fix - creates actors during email validation |
| `lib/mix/tasks/mobilizon/users/fix_missing_actors.ex` | Migration script to fix existing users |
| `scripts/run_actor_migration.sh` | Automated Docker migration script |
| `docs/ACTOR_FIX_README.md` | This file - overview |
| `docs/TECHNICAL_DETAILS.md` | Detailed technical analysis |
| `docs/DOCKER_MIGRATION_GUIDE.md` | Complete Docker instructions |

---

## 🚀 Quick Start for Docker

### For Production (Recommended)

Use the automated script:

```bash
./scripts/run_actor_migration.sh
```

This script will:
1. ✅ Create database backup
2. ✅ Show dry-run preview
3. ✅ Ask for confirmation
4. ✅ Run the migration
5. ✅ Verify results

### Manual Commands

```bash
# Dry-run (safe, no changes)
docker exec mobilizon_prod bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run(['--dry-run'])"

# Run for real
docker exec mobilizon_prod bin/mobilizon eval \
  "Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])"
```

---

## What Changed?

### 1. Code Fix (lib/graphql/resolvers/user.ex)

**Before:**
```elixir
def validate_user(_parent, %{token: token}, _resolution) do
  case Email.User.check_confirmation_token(token) do
    {:ok, %User{} = user} ->
      actor = Users.get_actor_for_user(user)  # Could be nil!
      # ... generate tokens ...
```

**After:**
```elixir
def validate_user(_parent, %{token: token}, _resolution) do
  with {:ok, %User{} = user} <- Email.User.check_confirmation_token(token),
       {:ok, %User{} = user} <- ensure_user_has_default_actor(user) do  # ← NEW!
    actor = Users.get_actor_for_user(user)  # Always has actor now
    # ... generate tokens ...
```

**Impact:** All new email/password users now get actors automatically upon email validation.

### 2. Migration Script

Created `Mix.Tasks.Mobilizon.Users.FixMissingActors` to fix existing users.

**What it does:**
- Finds users without actors (email/password only)
- Creates actors with usernames from emails
- Handles username conflicts with random suffixes

---

## Is It Safe?

✅ **YES!** See `docs/TECHNICAL_DETAILS.md` for full safety analysis.

**Quick safety points:**
- Only affects users WITHOUT actors
- Uses database transactions (atomic)
- Dry-run mode available
- Idempotent (safe to run multiple times)
- Comprehensive error handling

---

## Who Is Affected?

**Users who WILL be fixed:**
- ✅ Registered with email/password
- ✅ Validated their email
- ✅ Don't have a default actor

**Users NOT affected:**
- ❌ OAuth users (LinkedIn, Google, etc.)
- ❌ Users who already have actors
- ❌ Unconfirmed users
- ❌ Disabled users

---

## Testing the Fix

### After migration, verify:

1. **Check database:**
```bash
docker exec mobilizon_postgres_prod psql -U mobilizon mobilizon -c "
SELECT COUNT(*) FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false;"
```

Should return **0**.

2. **Test affected user can:**
- Log in ✅
- Create groups ✅
- Edit profile (username populated) ✅

---

## Rollback Plan

If something goes wrong:

```bash
# Restore from backup created by the script
docker exec -i mobilizon_postgres_prod psql -U mobilizon mobilizon < backup_YYYYMMDD_HHMMSS.sql

# Restart services
docker restart mobilizon_prod
```

---

## Support

- **Docker guide:** See `docs/DOCKER_MIGRATION_GUIDE.md`
- **Technical details:** See `docs/TECHNICAL_DETAILS.md`
- **Quick commands:** See `docs/QUICK_REFERENCE.md`

---

**Status:** ✅ Production Ready  
**Last Updated:** December 1, 2025  
**Tested:** Docker Compose production environment

