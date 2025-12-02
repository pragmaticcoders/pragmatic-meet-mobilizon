# Technical Details - Actor Fix

## Problem Analysis

### Root Cause

Email/password users don't get actors created automatically, unlike OAuth users:

**Email/Password Flow (BROKEN):**
```
Registration → Email Confirmation → ❌ NO ACTOR → Can't create groups
```

**OAuth Flow (WORKING):**
```
Registration → ✅ ACTOR CREATED → Can create groups
```

### Why It Fails

1. `validate_user()` confirms email but doesn't create actor
2. `login_user()` calls `ensure_user_has_default_actor()` BUT user may not login immediately
3. User tries to create group → needs `current_actor` → it's `nil` → fails

### Misleading Error

Error: **"You need to be logged-in to create a group"**

Reality: User IS logged in (`current_user` exists), but has no profile (`current_actor` is `nil`)

---

## Solution

### 1. Code Fix

**File:** `lib/graphql/resolvers/user.ex` line 267-295

**Change:** Add actor creation during email validation:

```elixir
def validate_user(_parent, %{token: token}, _resolution) do
  with {:ok, %User{} = user} <- Email.User.check_confirmation_token(token),
       {:ok, %User{} = user} <- ensure_user_has_default_actor(user) do  # ← Added
    # ... rest of function
  end
end
```

This reuses the existing `ensure_user_has_default_actor/1` function that was already called in `login_user/3`.

### 2. Migration Script

**File:** `lib/mix/tasks/mobilizon/users/fix_missing_actors.ex`

Fixes existing users who validated email before the fix was deployed.

---

## Safety Analysis

### Database Query Filters

The migration **ONLY** targets:

```sql
SELECT * FROM users 
WHERE default_actor_id IS NULL        -- No actor
  AND provider IS NULL                 -- Email/password only
  AND confirmed_at IS NOT NULL         -- Confirmed
  AND disabled = FALSE                 -- Active
```

### Transaction Safety

Uses `Actors.new_person/2` which:
```elixir
Multi.new()
|> Multi.insert(:person, ...)      # Create actor
|> Multi.insert(:token, ...)       # Create feed token
|> Multi.update(:user, ...)        # Set default_actor_id
|> Repo.transaction()              # ATOMIC - all or nothing
```

**Guarantees:**
- ✅ All operations succeed or all fail
- ✅ No orphan actors
- ✅ No partial states

### Username Generation

```
ewelina.lech@example.com
↓ Extract local part
ewelinlech
↓ If taken, add suffix
ewelinlech_7824
↓ Retry up to 100 times
ewelinlech_3951
↓ Fallback to timestamp
user_1733078400
```

**Collision Prevention:**
- 10,000 possible suffixes (0000-9999)
- 100 retry attempts = 1,000,000 combinations
- Timestamp fallback guarantees success

---

## Historical Context

Similar migration exists: `priv/repo/migrations/20210427091034_repair_users_default_actors.exs`

That migration fixed `default_actor_id` issues in 2021. Running successfully for 3+ years.

Our migration is safer because:
- ✅ Dry-run mode
- ✅ Better error handling
- ✅ More comprehensive (creates actors, not just links)

---

## Testing Strategy

### Unit Testing

The `ensure_user_has_default_actor/1` function already has tests via `login_user/3`.

### Integration Testing

```bash
# 1. Register new email/password user
# 2. Validate email
# 3. Immediately try to create group
# Expected: Success ✅
```

### Migration Testing

```bash
# 1. Run in dry-run mode
mix mobilizon.users.fix_missing_actors --dry-run

# 2. Verify output shows correct users
# 3. Run for real
mix mobilizon.users.fix_missing_actors

# 4. Verify all users have actors
```

---

## Performance Impact

### Registration Flow

**Before:** 1 database operation (confirm email)  
**After:** 4 database operations (confirm email + create actor + token + update user)

**Impact:** Negligible - happens once per user

### Migration

**For N affected users:**
- N database transactions
- Each transaction: 3-4 operations
- Sequential processing (safety over speed)

**Estimate:** ~100ms per user  
**Example:** 100 users = ~10 seconds

---

## Error Scenarios

### Scenario 1: Username Already Exists

**Handling:**
```elixir
case Actors.get_local_actor_by_name(username) do
  nil -> use_username
  _actor -> add_random_suffix_and_retry
end
```

**Result:** Generates unique username

### Scenario 2: Database Connection Lost

**Handling:** Transaction rolls back, error logged, script continues with next user

**Result:** Failed user can be retried

### Scenario 3: Invalid Email Format

**Handling:** Falls back to "user" as base username

**Result:** Creates "user_XXXX" username

---

## Monitoring

### Check for Affected Users

```sql
SELECT COUNT(*) as users_without_actors
FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false;
```

**Alert if:** count > 0 after deployment

### Check Migration Success

```sql
SELECT email, created_at
FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false
ORDER BY created_at DESC;
```

Shows specific users still affected.

---

## Rollback Procedure

If fix causes issues:

1. **Revert code change:**
```bash
git revert <commit-hash>
```

2. **Actors created by migration remain but are harmless:**
- They're valid actors
- They're linked to correct users
- Users can use them

3. **If needed, remove specific actor:**
```sql
-- Get actor_id
SELECT default_actor_id FROM users WHERE email = 'user@example.com';

-- Remove link (actor remains in DB)
UPDATE users SET default_actor_id = NULL WHERE email = 'user@example.com';
```

**Note:** Don't delete actors - they may be used in other places (events, comments, etc.)

---

## Future Improvements

### Prevent Issue Entirely

Option 1: Create actor during registration (before email confirmation)
- **Pro:** User always has actor
- **Con:** Orphan actors for unconfirmed users

Option 2: Require profile creation step
- **Pro:** User chooses username
- **Con:** Extra step in registration flow

Option 3: Current solution (actor on email confirmation)
- **Pro:** No orphan actors, automatic flow
- **Con:** Requires migration for existing users (one-time)

**Recommendation:** Keep current solution ✅

---

## Related Files

| File | Purpose |
|------|---------|
| `lib/graphql/resolvers/user.ex` | validate_user fix |
| `lib/graphql/resolvers/group.ex` | Requires current_actor |
| `lib/graphql/middleware/current_actor_provider.ex` | Loads current_actor |
| `lib/mobilizon/users/users.ex` | update_user_default_actor |
| `lib/mobilizon/actors/actors.ex` | new_person |

---

**Author:** Technical Analysis  
**Date:** December 1, 2025  
**Status:** ✅ Reviewed & Approved

