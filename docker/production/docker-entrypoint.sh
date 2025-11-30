#!/bin/sh

set -e

# Fix execute permissions on mobilizon_ctl if needed
chmod +x /bin/mobilizon_ctl 2>/dev/null || true

# Set configuration path
export MOBILIZON_CONFIG_PATH=/etc/mobilizon/config.exs

echo "-- Waiting for database..."
while ! pg_isready -U ${MOBILIZON_DATABASE_USERNAME} -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -d ${MOBILIZON_DATABASE_DBNAME} -t 1; do
   sleep 1s
done

echo "-- Creating required database extensions..."
PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS unaccent;'

echo "-- Running migrations..."
/bin/mobilizon_ctl migrate

# Seed E2E test data if in E2E environment
if [ "$MOBILIZON_ENV" = "e2e" ]; then
  echo "-- Seeding E2E test data..."
  echo "-- Creating test users: user@email.com, confirmed@email.com, unconfirmed@email.com"
  if /bin/mobilizon eval 'Application.put_env(:mobilizon, :env, :e2e); Application.ensure_all_started(:mobilizon); Code.eval_string(File.read!("priv/repo/e2e.seed.exs"))'; then
    echo "-- E2E test data seeded successfully"
  else
    echo "ERROR: E2E seed failed! Test users were not created."
    echo "This will cause e2e tests to fail. Check the error above."
    exit 1
  fi
fi

#echo "-- Running admin commands..."
# NOTE: CLI commands must use eval mode during startup (RPC mode fails on running containers)
# WORKAROUND: Add CLI commands here with MOBILIZON_CTL_RPC_DISABLED=true for distributed Erlang issue
# TODO: Fix distributed Erlang configuration to allow CLI commands on running containers
#MOBILIZON_CTL_RPC_DISABLED=true /bin/mobilizon_ctl users.new "new@user.com" --admin --password "password"

echo "-- Starting!"
exec /bin/mobilizon start