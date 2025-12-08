#!/bin/sh

set -e

echo "-- Waiting for database..."
# Wait for PostgreSQL server to be ready (using default postgres user or configured user)
until pg_isready -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432}; do
   echo "Waiting for PostgreSQL to be ready..."
   sleep 2s
done

# Only wait for specific database if not in test mode (database might not exist yet in test)
if [ "$MIX_ENV" != "test" ]; then
  # Wait for the specific database to be available
  while ! pg_isready -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U ${MOBILIZON_DATABASE_USERNAME} -d ${MOBILIZON_DATABASE_DBNAME}; do
     echo "Waiting for database ${MOBILIZON_DATABASE_DBNAME} to be ready..."
     sleep 2s
  done
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

# Setup timezone data if not present
if [ ! -f "/var/lib/mobilizon/timezones/timezones-geodata.dets" ]; then
  echo "-- Setting up timezone data..."
  mkdir -p /var/lib/mobilizon/timezones
  mix tz_world.update || true
  # If the update places the file in the build directory, copy it to the expected location
  if [ -f "_build/dev/lib/tz_world/priv/timezones-geodata.dets" ]; then
    cp _build/dev/lib/tz_world/priv/timezones-geodata.dets /var/lib/mobilizon/timezones/
    echo "-- Timezone data setup complete"
  fi
else
  echo "-- Timezone data already present, skipping..."
fi

# Skip database setup in test mode (handled by mix prepare_test)
if [ "$MIX_ENV" != "test" ]; then
  echo "-- Creating database extensions..."
  PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
  PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
  PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS unaccent;'

  echo "-- Running migrations..."
  mix mobilizon.ecto.migrate
fi

# If no command is provided, start Phoenix server
# Otherwise, execute the provided command
if [ $# -eq 0 ]; then
  echo "-- Starting Phoenix server with Vite!"
  echo "-- Phoenix will be available at http://localhost:4000"
  echo "-- Vite dev server will run on port 5173 (proxied by Phoenix)"
  exec mix phx.server
else
  # Execute the provided command
  exec "$@"
fi 