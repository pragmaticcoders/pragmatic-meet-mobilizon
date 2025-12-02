#!/bin/sh

set -e

echo "-- Waiting for database..."
# Wait for PostgreSQL to be ready
while ! pg_isready -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U postgres; do
   echo "Waiting for PostgreSQL to be ready..."
   sleep 2s
done

# Check if the database exists, if not skip the readiness check
# The database will be created by ecto.create later
if PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U ${MOBILIZON_DATABASE_USERNAME} -lqt | cut -d \| -f 1 | grep -qw ${MOBILIZON_DATABASE_DBNAME}; then
  echo "Database ${MOBILIZON_DATABASE_DBNAME} exists, waiting for it to be ready..."
  while ! pg_isready -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U ${MOBILIZON_DATABASE_USERNAME} -d ${MOBILIZON_DATABASE_DBNAME}; do
     echo "Waiting for database ${MOBILIZON_DATABASE_DBNAME} to be ready..."
     sleep 2s
  done
else
  echo "Database ${MOBILIZON_DATABASE_DBNAME} does not exist yet, skipping readiness check (will be created later)..."
fi

# Check if dependencies need to be installed
if [ ! -d "deps" ] || [ ! -d "deps/phoenix" ]; then
  echo "-- Fetching Elixir dependencies..."
  mix deps.get
else
  echo "-- Elixir dependencies already present, skipping..."
fi

# Check if node_modules needs to be installed
if [ ! -d "node_modules" ] || [ ! -d "node_modules/vite" ]; then
  echo "-- Installing Node.js dependencies..."
  npm install
else
  echo "-- Node.js dependencies already present, skipping..."
fi

# Build picture assets if not already built
if [ ! -d "priv/static/img/pics" ]; then
  echo "-- Building picture assets..."
  npm run build:pictures
else
  echo "-- Picture assets already built, skipping..."
fi

# Compile Elixir assets
echo "-- Compiling Elixir assets..."
mix compile

# Only create extensions if the database exists (it will be created by migrations if it doesn't)
if PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U ${MOBILIZON_DATABASE_USERNAME} -lqt | cut -d \| -f 1 | grep -qw ${MOBILIZON_DATABASE_DBNAME}; then
  echo "-- Creating database extensions..."
  PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
  PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
  PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS unaccent;'
else
  echo "-- Database does not exist yet, skipping extension creation (will be handled by migrations)..."
fi

# Only run migrations if the database exists (test setup will handle migrations later)
if PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U ${MOBILIZON_DATABASE_USERNAME} -lqt | cut -d \| -f 1 | grep -qw ${MOBILIZON_DATABASE_DBNAME}; then
  echo "-- Running migrations..."
  mix mobilizon.ecto.migrate
else
  echo "-- Database does not exist yet, skipping migrations (will be handled by ecto.setup or prepare_test)..."
fi

echo "-- Starting Phoenix server with Vite!"
echo "-- Phoenix will be available at http://localhost:4000"
echo "-- Vite dev server will run on port 5173 (proxied by Phoenix)"
exec mix phx.server 