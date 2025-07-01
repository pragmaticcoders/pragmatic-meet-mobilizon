#!/bin/sh

set -e

echo "=== Mobilizon Docker Setup Script ==="
echo "This script performs initial setup tasks that are not needed on every startup."
echo ""

echo "-- Building frontend assets..."
npm run build

echo "-- Seeding database with initial data..."
mix run priv/repo/seeds.exs

echo ""
echo "=== Setup Complete ==="
echo "You can now start the application with: docker compose up" 