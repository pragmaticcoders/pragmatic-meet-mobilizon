# Mobilizon Maintenance Tasks Guide

A comprehensive guide to all available maintenance and administrative tasks in Mobilizon.

## 📋 Table of Contents

- [Overview](#overview)
- [Task Categories](#task-categories)
- [Maintenance Tasks](#1-maintenance-tasks)
- [User Management](#2-user-management)
- [Actor Management](#3-actor-management)
- [Media Management](#4-media-management)
- [Federation/Relay Management](#5-federationrelay-management)
- [Instance Management](#6-instance-management)
- [Utility Tasks](#7-utility-tasks)
- [Database Management](#8-database-management)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🔍 Overview

Mobilizon provides a comprehensive set of Mix tasks for system maintenance, user management, content moderation, and administrative operations. These tasks help you maintain a healthy, secure, and efficient Mobilizon instance.

### Quick Reference

| Category | Task Prefix | Purpose |
|----------|-------------|---------|
| Maintenance | `mobilizon.maintenance.*` | System maintenance and monitoring |
| Users | `mobilizon.users.*` | User account management |
| Actors | `mobilizon.actors.*` | Profile and group management |
| Media | `mobilizon.media.*` | File and media cleanup |
| Relay | `mobilizon.relay.*` | Federation relay management |
| Instance | `mobilizon.instance.*` | Instance configuration |
| Database | `mobilizon.ecto.*` | Database operations |

## 📊 Task Categories

## 1. 🔍 **Maintenance Tasks** (`mix mobilizon.maintenance.*`)

### **Spam Detection**
Scan all profiles and events against spam detector and report suspicious content.

```bash
mix mobilizon.maintenance.detect_spam [options]
```

**Options:**
- `-d, --dry_run` - Dry run mode (show what would be detected)
- `-v, --verbose` - Verbose output with detailed information
- `-f, --forward_reports` - Forward reports to other federated instances
- `-l, --local_only` - Only scan local content (skip remote content)
- `-p, --only_profiles` - Only scan actor profiles
- `-e, --only_events` - Only scan events

**Examples:**
```bash
# Safe scan - see what would be detected
mix mobilizon.maintenance.detect_spam --dry-run --verbose

# Scan only local events for spam
mix mobilizon.maintenance.detect_spam --local-only --only-events

# Comprehensive scan with reporting
mix mobilizon.maintenance.detect_spam --verbose --forward-reports
```

**Requirements:** Requires Akismet API key configuration for spam detection.

---

### **Email Configuration Testing**
Send test emails to verify your email configuration is working properly.

```bash
mix mobilizon.maintenance.test_emails [email] [options]
```

**Options:**
- `-l, --locale LOCALE` - Locale for email content (en_US, de_DE, fr_FR, etc.)
- `-h, --help` - Show detailed help

**Examples:**
```bash
# Test email to admin
mix mobilizon.maintenance.test_emails admin@example.com

# Test with specific locale
mix mobilizon.maintenance.test_emails admin@example.com --locale fr_FR

# Show help
mix mobilizon.maintenance.test_emails --help
```

---

## 2. 👥 **User Management** (`mix mobilizon.users.*`)

### **Create New User**
Create new user accounts with various roles and configurations.

```bash
mix mobilizon.users.new [email] [options]
```

**Options:**
- `-p, --password PASSWORD` - Set custom password (auto-generated if not provided)
- `--moderator` - Create user with moderator role
- `--admin` - Create user with administrator role
- `--profile_username USERNAME` - Set initial profile username
- `--profile_display_name NAME` - Set profile display name
- `--provider PROVIDER` - Set authentication provider

**Examples:**
```bash
# Create administrator
mix mobilizon.users.new admin@example.com --admin

# Create user with custom password and profile
mix mobilizon.users.new user@example.com --password "securepass123" --profile_username "alice"

# Create moderator with display name
mix mobilizon.users.new mod@example.com --moderator --profile_display_name "Community Moderator"
```

---

### **Show User Information**
Display detailed information about a user account.

```bash
mix mobilizon.users.show [email]
```

**Examples:**
```bash
# Show user details
mix mobilizon.users.show admin@example.com

# View user profile information
mix mobilizon.users.show user@example.com
```

**Output includes:** Email, role, confirmation status, associated profiles, creation date.

---

### **Modify User**
Update user properties and permissions.

```bash
mix mobilizon.users.modify [email] [options]
```

**Options:**
- `--admin` - Promote user to administrator
- `--moderator` - Set user as moderator
- `--user` - Demote to regular user
- `--enable` - Enable user account
- `--disable` - Disable user account
- `--confirm` - Confirm user email address
- `--unconfirm` - Mark user email as unconfirmed

**Examples:**
```bash
# Promote user to admin
mix mobilizon.users.modify user@example.com --admin

# Disable problematic user
mix mobilizon.users.modify spammer@example.com --disable

# Manually confirm user email
mix mobilizon.users.modify user@example.com --confirm

# Demote admin to regular user
mix mobilizon.users.modify former-admin@example.com --user
```

---

### **Delete User**
Permanently delete user accounts and associated data.

```bash
mix mobilizon.users.delete [email] [options]
```

**Options:**
- `-y, --assume_yes` - Skip confirmation prompts
- `-k, --keep_email` - Reserve the email address

**Examples:**
```bash
# Delete user with confirmation
mix mobilizon.users.delete user@example.com

# Force delete without prompts
mix mobilizon.users.delete spammer@example.com --assume-yes

# Delete but keep email reserved
mix mobilizon.users.delete user@example.com --keep-email
```

**⚠️ Warning:** This permanently deletes all user data including profiles, events, and posts.

---

### **Clean Unconfirmed Users**
Remove user accounts that haven't confirmed their email addresses.

```bash
mix mobilizon.users.clean [options]
```

**Options:**
- `--dry_run` - Show what would be deleted without deleting
- `-d, --days DAYS` - Grace period in days (default: from instance config)
- `-v, --verbose` - Show detailed list of users to be deleted

**Examples:**
```bash
# Preview what would be cleaned
mix mobilizon.users.clean --dry-run --verbose

# Clean users unconfirmed for 7+ days
mix mobilizon.users.clean --days 7

# Clean with default grace period
mix mobilizon.users.clean --verbose
```

**Default grace period:** Configured in instance settings (typically 48 hours).

---

## 3. 🎭 **Actor Management** (`mix mobilizon.actors.*`)

### **Show Actor Information**
Display detailed information about an actor (profile or group).

```bash
mix mobilizon.actors.show [username_or_federated_address]
```

**Examples:**
```bash
# Show local actor
mix mobilizon.actors.show alice

# Show remote actor
mix mobilizon.actors.show alice@remote-instance.com

# Show group information
mix mobilizon.actors.show my-local-group
```

**Output includes:** Type, domain, name, summary, associated user, creation date.

---

### **Create New Actor**
Create new actor profiles or groups.

```bash
mix mobilizon.actors.new [options]
```

**Options:**
- `--username USERNAME` - Actor username (required)
- `--display_name NAME` - Actor display name
- `--summary SUMMARY` - Actor bio/summary
- `--email EMAIL` - Associated user email (required)
- `--avatar URL` - Avatar image URL
- `--banner URL` - Banner image URL

**Examples:**
```bash
# Create basic actor
mix mobilizon.actors.new --username "bot1" --email "admin@example.com"

# Create actor with full profile
mix mobilizon.actors.new \
  --username "community-bot" \
  --display_name "Community Bot" \
  --summary "Automated community management" \
  --email "admin@example.com"
```

---

### **Delete Actor**
Delete an actor profile or group and all associated content.

```bash
mix mobilizon.actors.delete [username] [options]
```

**Options:**
- `-y, --assume_yes` - Skip confirmation prompts
- `-k, --keep_username` - Reserve the username

**Examples:**
```bash
# Delete with confirmation
mix mobilizon.actors.delete spam_profile

# Force delete group
mix mobilizon.actors.delete old_group --assume-yes

# Delete but reserve username
mix mobilizon.actors.delete former_user --keep-username
```

**⚠️ Warning:** Deletes all content including events, posts, and comments. Group members will be notified.

---

### **Refresh Actor**
Refresh actor information from remote federated instances.

```bash
mix mobilizon.actors.refresh [federated_address]
```

**Examples:**
```bash
# Refresh remote actor data
mix mobilizon.actors.refresh alice@remote-instance.com

# Update group information
mix mobilizon.actors.refresh community@another-instance.org
```

**Use case:** Updates profile information, avatar, banner, and other metadata from remote instances.

---

## 4. 📁 **Media Management** (`mix mobilizon.media.*`)

### **Clean Orphaned Media**
Remove media files that are no longer referenced by any content.

```bash
mix mobilizon.media.clean_orphan [options]
```

**Options:**
- `--dry_run` - Show what would be deleted without deleting
- `-d, --days DAYS` - Grace period in days (default: 48 hours)
- `-v, --verbose` - Show detailed list of files

**Examples:**
```bash
# Preview orphaned files
mix mobilizon.media.clean_orphan --dry-run --verbose

# Clean files older than 7 days
mix mobilizon.media.clean_orphan --days 7

# Clean with default grace period
mix mobilizon.media.clean_orphan --verbose
```

**What gets cleaned:** Uploaded images, documents, and other media files not linked to any events, posts, or profiles.

---

## 5. 🔄 **Federation/Relay Management** (`mix mobilizon.relay.*`)

### **Follow Remote Relay**
Connect to and follow a remote relay instance.

```bash
mix mobilizon.relay.follow [relay_url]
```

**Examples:**
```bash
# Follow a public relay
mix mobilizon.relay.follow https://relay.joinmobilizon.org/relay

# Follow custom relay
mix mobilizon.relay.follow https://relay.example.com/relay
```

**Effect:** Your instance will receive public events from the relay network.

---

### **Unfollow Remote Relay**
Disconnect from a remote relay instance.

```bash
mix mobilizon.relay.unfollow [relay_url]
```

**Examples:**
```bash
# Unfollow relay
mix mobilizon.relay.unfollow https://relay.example.com/relay

# Stop receiving from main relay
mix mobilizon.relay.unfollow https://relay.joinmobilizon.org/relay
```

---

### **Accept Relay Follow**
Accept a follow request from another relay instance.

```bash
mix mobilizon.relay.accept [relay_url]
```

**Examples:**
```bash
# Accept follow request
mix mobilizon.relay.accept https://requesting-relay.example.com/relay
```

---

### **Refresh Relay**
Refresh connection and synchronize with a relay instance.

```bash
mix mobilizon.relay.refresh [relay_url]
```

**Examples:**
```bash
# Refresh relay connection
mix mobilizon.relay.refresh https://relay.example.com/relay
```

---

## 6. 🏢 **Instance Management**

### **Instance Configuration**
Manage instance-wide settings and configuration.

```bash
mix mobilizon.instance [subcommand]
```

**Available subcommands:** Run without arguments to see available options.

---

### **Create Bot Account**
Create specialized bot accounts for automated tasks.

```bash
mix mobilizon.create_bot [options]
```

**Options:**
- `--name NAME` - Bot display name
- `--summary SUMMARY` - Bot description
- `--email EMAIL` - Associated email address

**Examples:**
```bash
# Create moderation bot
mix mobilizon.create_bot \
  --name "Moderation Bot" \
  --summary "Automated moderation tasks" \
  --email "bot@example.com"

# Create event bot
mix mobilizon.create_bot \
  --name "Event Bot" \
  --summary "Automated event management" \
  --email "events@example.com"
```

---

## 7. 🗺️ **Utility Tasks**

### **Generate Sitemap**
Generate XML sitemaps for search engine optimization.

```bash
mix mobilizon.site_map
```

**Output:** Creates sitemap files in the configured static directory for search engines.

**Frequency:** Run periodically (daily/weekly) or after significant content changes.

---

### **Update Timezone Data**
Update the timezone database used for event scheduling.

```bash
mix mobilizon.tz_world.update
```

**Purpose:** Ensures accurate timezone handling for events across different regions.

**Frequency:** Run monthly or when timezone rules change.

---

### **Web Push Management**
Manage web push notification settings and certificates.

```bash
mix mobilizon.web_push [subcommand]
```

**Available subcommands:** Run without arguments to see available options.

---

## 8. 🗄️ **Database Management**

### **Run Migrations**
Apply pending database schema changes.

```bash
mix mobilizon.ecto.migrate
```

**Use case:** After updating Mobilizon or when instructed by upgrade guides.

---

### **Rollback Migrations**
Revert recent database changes.

```bash
mix mobilizon.ecto.rollback [options]
```

**⚠️ Warning:** Use only when instructed by support or documentation.

---

## 💼 Usage Examples

### **Weekly Maintenance Routine**

```bash
#!/bin/bash
# Weekly Mobilizon maintenance script

echo "=== Starting Weekly Maintenance ==="

# 1. Clean up unconfirmed users (preview first)
echo "Checking unconfirmed users..."
mix mobilizon.users.clean --dry-run --verbose
read -p "Proceed with cleanup? (y/n): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mix mobilizon.users.clean --days 7
fi

# 2. Clean orphaned media files
echo "Cleaning orphaned media..."
mix mobilizon.media.clean_orphan --dry-run --verbose
read -p "Proceed with media cleanup? (y/n): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mix mobilizon.media.clean_orphan --days 30
fi

# 3. Scan for spam content
echo "Scanning for spam..."
mix mobilizon.maintenance.detect_spam --dry-run --verbose

# 4. Test email configuration
echo "Testing email configuration..."
mix mobilizon.maintenance.test_emails admin@example.com

# 5. Update timezone data
echo "Updating timezone data..."
mix mobilizon.tz_world.update

# 6. Generate fresh sitemap
echo "Generating sitemap..."
mix mobilizon.site_map

echo "=== Maintenance Complete ==="
```

---

### **User Administration Examples**

```bash
# New instance setup
echo "Creating admin user..."
mix mobilizon.users.new admin@example.com --admin \
  --profile_username "admin" \
  --profile_display_name "Instance Administrator"

# Create moderators
echo "Creating moderator accounts..."
mix mobilizon.users.new mod1@example.com --moderator \
  --profile_username "moderator1"

mix mobilizon.users.new mod2@example.com --moderator \
  --profile_username "moderator2"

# Verify user creation
mix mobilizon.users.show admin@example.com
mix mobilizon.users.show mod1@example.com
```

---

### **Content Moderation Workflow**

```bash
# 1. Scan for spam (safe mode first)
echo "Scanning for potential spam..."
mix mobilizon.maintenance.detect_spam --dry-run --verbose --local-only

# 2. If spam detected, investigate specific content
echo "Checking specific actors..."
mix mobilizon.actors.show suspicious_username

# 3. Take action if confirmed spam
echo "Removing spam actor..."
mix mobilizon.actors.delete spam_profile --assume-yes

# 4. Clean up related media
echo "Cleaning related media..."
mix mobilizon.media.clean_orphan --days 1 --verbose

# 5. Check for associated user account
mix mobilizon.users.show spammer@example.com
mix mobilizon.users.delete spammer@example.com --assume-yes
```

---

### **Federation Management**

```bash
# Connect to main relay network
echo "Connecting to relay network..."
mix mobilizon.relay.follow https://relay.joinmobilizon.org/relay

# Check connection status
echo "Checking relay status..."
mix mobilizon.relay.refresh https://relay.joinmobilizon.org/relay

# Refresh remote actor data
echo "Refreshing remote actors..."
mix mobilizon.actors.refresh popular_group@remote-instance.com
```

---

## ⚠️ Best Practices

### **Safety First**
1. **Always use `--dry-run` first** for destructive operations
2. **Backup your database** before running cleanup tasks
3. **Test on staging** before running on production
4. **Monitor disk space** when cleaning media files
5. **Check logs** after running maintenance tasks

### **Scheduling**
1. **Run during low-traffic periods** for better performance
2. **Schedule regular maintenance** (weekly/monthly)
3. **Monitor resource usage** during batch operations
4. **Set up monitoring** for critical tasks

### **Security**
1. **Verify spam detection** results before taking action
2. **Keep audit logs** of administrative actions
3. **Restrict admin access** to maintenance tasks
4. **Regular security scans** for suspicious content

---

## 🔧 Environment-Specific Usage

### **Development Environment**
```bash
# Direct execution in development
mix mobilizon.users.clean --dry-run
mix mobilizon.maintenance.detect_spam --local-only
```

### **Docker Development**
```bash
# Using Docker Compose
docker compose -f docker/development/docker-compose.yml run --rm api \
  mix mobilizon.users.clean --dry-run

docker compose -f docker/development/docker-compose.yml run --rm api \
  mix mobilizon.media.clean_orphan --verbose
```

### **Production Environment**
```bash
# Using releases
./bin/mobilizon rpc "Mix.Tasks.Mobilizon.Users.Clean.run(['--dry-run'])"

# Or if CLI is configured
./bin/mobilizon users.clean --dry-run
```

---

## 🐛 Troubleshooting

### **Common Issues**

#### **Task Won't Start**
```bash
# Check if Mobilizon is running
ps aux | grep mobilizon

# Check database connection
mix mobilizon.ecto.migrate
```

#### **Permission Errors**
```bash
# Check file permissions
ls -la uploads/
chown -R mobilizon:mobilizon uploads/

# Check database permissions
psql -h localhost -U mobilizon mobilizon_prod -c "\l"
```

#### **Memory Issues**
```bash
# Monitor memory usage
free -h
top -p $(pgrep -f mobilizon)

# Adjust batch sizes for large operations
```

#### **Email Tasks Failing**
```bash
# Check SMTP configuration
mix mobilizon.maintenance.test_emails admin@example.com

# Verify environment variables
env | grep MOBILIZON_SMTP
```

### **Getting Help**
1. **Check logs**: `tail -f log/prod.log`
2. **Verify configuration**: Review environment variables
3. **Test database**: `mix mobilizon.ecto.migrate`
4. **Check disk space**: `df -h`
5. **Monitor processes**: `htop` or `ps aux | grep mobilizon`

---

## 📚 Additional Resources

- **Main Documentation**: https://docs.joinmobilizon.org
- **Administration Guide**: https://docs.joinmobilizon.org/administration/
- **Troubleshooting**: https://docs.joinmobilizon.org/administration/troubleshooting/
- **Configuration**: https://docs.joinmobilizon.org/administration/configuration/

---

**Last Updated:** $(date)
**Mobilizon Version:** 5.1.4+

---

*This documentation covers all available maintenance tasks in Mobilizon. Always refer to the latest official documentation for the most up-to-date information.*
