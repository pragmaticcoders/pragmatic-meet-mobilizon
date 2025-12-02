#!/bin/bash
#
# Mobilizon Actor Migration Script for Docker
# This script safely runs the fix_missing_actors migration in your Docker environment
#

set -e  # Exit on error

# Configuration - Update these if your container names are different
CONTAINER_NAME="${MOBILIZON_CONTAINER:-mobilizon_prod}"
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-mobilizon_postgres_prod}"
DB_USER="${DB_USER:-mobilizon}"
DB_NAME="${DB_NAME:-mobilizon}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

check_container() {
  if ! docker ps --format '{{.Names}}' | grep -q "^$1$"; then
    print_error "Container '$1' is not running!"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
  fi
  print_success "Container '$1' is running"
}

# Main script
print_header "Mobilizon Actor Migration for Docker"

echo "This script will fix users who are missing actor profiles."
echo ""
echo "Configuration:"
echo "  - Mobilizon container: $CONTAINER_NAME"
echo "  - Postgres container: $POSTGRES_CONTAINER"
echo "  - Database user: $DB_USER"
echo "  - Database name: $DB_NAME"
echo ""

# Step 1: Check containers
print_info "Step 1: Checking Docker containers..."
check_container "$CONTAINER_NAME"
check_container "$POSTGRES_CONTAINER"
echo ""

# Step 2: Create backup
print_header "Step 2: Creating Database Backup"
BACKUP_FILE="mobilizon_backup_$(date +%Y%m%d_%H%M%S).sql"
print_info "Backing up database to: $BACKUP_FILE"

if docker exec "$POSTGRES_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"; then
  BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  print_success "Backup created successfully ($BACKUP_SIZE)"
else
  print_error "Backup failed!"
  exit 1
fi
echo ""

# Step 3: Check current state
print_header "Step 3: Checking Current State"
print_info "Counting users without actors..."

USERS_WITHOUT_ACTORS=$(docker exec "$POSTGRES_CONTAINER" psql -U "$DB_USER" "$DB_NAME" -t -c "
SELECT COUNT(*) 
FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false;
" | tr -d ' ')

if [ "$USERS_WITHOUT_ACTORS" -eq "0" ]; then
  print_success "All users already have actors - nothing to fix!"
  echo ""
  print_info "Backup saved: $BACKUP_FILE (you can delete it)"
  exit 0
fi

print_warning "Found $USERS_WITHOUT_ACTORS user(s) without actors"
echo ""

# Step 4: Dry-run
print_header "Step 4: Running Dry-Run (Preview)"
print_info "This shows what WOULD be done without making changes..."
echo ""

if docker exec "$CONTAINER_NAME" bin/mobilizon eval 'Mix.Tasks.Mobilizon.Users.FixMissingActors.run(["--dry-run"])'; then
  print_success "Dry-run completed successfully"
else
  print_error "Dry-run failed!"
  exit 1
fi
echo ""

# Step 5: Confirm
print_header "Step 5: Confirmation"
print_warning "Review the dry-run output above carefully!"
echo ""
echo "The migration will:"
echo "  - Create actor profiles for users without them"
echo "  - Generate usernames from email addresses"
echo "  - Set default actors for affected users"
echo ""
read -p "Do you want to proceed with the actual migration? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  print_warning "Migration cancelled by user"
  print_info "Backup saved: $BACKUP_FILE (you can delete it)"
  exit 0
fi
echo ""

# Step 6: Run migration
print_header "Step 6: Running Migration"
print_info "Applying changes to database..."
echo ""

if docker exec "$CONTAINER_NAME" bin/mobilizon eval 'Mix.Tasks.Mobilizon.Users.FixMissingActors.run([])'; then
  print_success "Migration completed successfully!"
else
  print_error "Migration failed!"
  echo ""
  print_info "Your database backup is available at: $BACKUP_FILE"
  print_info "To restore: docker exec -i $POSTGRES_CONTAINER psql -U $DB_USER $DB_NAME < $BACKUP_FILE"
  exit 1
fi
echo ""

# Step 7: Verify
print_header "Step 7: Verifying Results"
print_info "Checking if all users now have actors..."

REMAINING=$(docker exec "$POSTGRES_CONTAINER" psql -U "$DB_USER" "$DB_NAME" -t -c "
SELECT COUNT(*) 
FROM users 
WHERE default_actor_id IS NULL 
  AND provider IS NULL 
  AND confirmed_at IS NOT NULL 
  AND disabled = false;
" | tr -d ' ')

if [ "$REMAINING" -eq "0" ]; then
  print_success "Verification passed - all users now have actors!"
else
  print_warning "Warning: $REMAINING user(s) still without actors"
  print_info "Check the migration output above for errors"
fi
echo ""

# Step 8: Summary
print_header "Migration Complete!"

echo "Summary:"
echo "  - Users fixed: $USERS_WITHOUT_ACTORS"
echo "  - Remaining issues: $REMAINING"
echo "  - Backup location: $BACKUP_FILE"
echo ""

if [ "$REMAINING" -eq "0" ]; then
  print_success "All users have been fixed successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Have affected users log out and log back in"
  echo "  2. Verify they can now create groups"
  echo "  3. Check their profile shows a username"
  echo "  4. Keep the backup for a few days, then delete: $BACKUP_FILE"
else
  print_warning "Some users still need attention"
  echo ""
  echo "Next steps:"
  echo "  1. Check the error messages above"
  echo "  2. Investigate the problematic users"
  echo "  3. Fix underlying issues and run again"
  echo "  4. Keep the backup: $BACKUP_FILE"
fi

echo ""
