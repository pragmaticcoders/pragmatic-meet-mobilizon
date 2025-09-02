#!/bin/bash

# Create final cleanup script using echo statements that handles all constraints
echo "Creating final_cleanup_generated.sql..."

cat > final_cleanup_generated.sql << 'EOF'
-- Final cleanup script that handles all constraints properly
-- WARNING: This will delete ALL user data. Make sure you have a backup!

BEGIN;

-- Step 1: Delete admin_action_logs first (they reference actors with NOT NULL constraint)
DELETE FROM admin_action_logs WHERE 1 = 1;

-- Step 2: Delete other data that references actors
DO $$
BEGIN
    -- Delete from reports if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reports') THEN
        DELETE FROM reports;
    END IF;

    -- Delete from activities if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'activities') THEN
        DELETE FROM activities;
    END IF;

    -- Delete from posts if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'posts') THEN
        DELETE FROM posts;
    END IF;

    -- Delete from members if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'members') THEN
        DELETE FROM members;
    END IF;

    -- Delete from followers if table exists  
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'followers') THEN
        DELETE FROM followers;
    END IF;

    -- Delete from user settings and related tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_settings') THEN
        DELETE FROM user_settings;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_activity_settings') THEN
        DELETE FROM user_activity_settings;
    END IF;

    -- Delete from feed tokens if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'feed_tokens') THEN
        DELETE FROM feed_tokens;
    END IF;
END $$;

-- Step 3: Delete comments (this was causing the original constraint violation)
DELETE FROM comments WHERE 1 = 1;

-- Step 4: Delete other core data
DELETE FROM participants WHERE 1 = 1;
DELETE FROM events WHERE 1 = 1;

-- Step 5: Now we can safely delete actors
DELETE FROM actors WHERE 1 = 1;

-- Step 6: Finally delete users
DELETE FROM users WHERE 1 = 1;

COMMIT;

-- Verify cleanup
SELECT
    'users' AS table_name,
    count(*) AS remaining_records
FROM users
UNION ALL
SELECT
    'actors' AS table_name,
    count(*) AS remaining_records
FROM actors
UNION ALL
SELECT
    'events' AS table_name,
    count(*) AS remaining_records
FROM events
UNION ALL
SELECT
    'comments' AS table_name,
    count(*) AS remaining_records
FROM comments
UNION ALL
SELECT
    'participants' AS table_name,
    count(*) AS remaining_records
FROM participants;
EOF

echo "✅ Created final_cleanup_generated.sql successfully!"
echo ""
echo "This script fixes the admin_action_logs constraint issue by deleting those records first."
echo ""
echo "To run: psql -h postgres -U mobilizon mobilizon -f final_cleanup_generated.sql"
echo ""
echo "⚠️  IMPORTANT: Make sure you have a database backup before running!"
