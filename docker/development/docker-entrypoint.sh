#!/bin/sh

set -e

echo "-- Waiting for database..."
# Wait for PostgreSQL to be ready
while ! pg_isready -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U postgres; do
   echo "Waiting for PostgreSQL to be ready..."
   sleep 2s
done

# Wait for the specific database to be available
while ! pg_isready -h ${MOBILIZON_DATABASE_HOST} -p ${MOBILIZON_DATABASE_PORT:-5432} -U ${MOBILIZON_DATABASE_USERNAME} -d ${MOBILIZON_DATABASE_DBNAME}; do
   echo "Waiting for database ${MOBILIZON_DATABASE_DBNAME} to be ready..."
   sleep 2s
done

echo "-- Fetching dependencies..."
mix deps.get

echo "-- Installing Node.js dependencies..."
npm install

echo "-- Creating database extensions..."
PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
PGPASSWORD=$MOBILIZON_DATABASE_PASSWORD psql -U $MOBILIZON_DATABASE_USERNAME -d $MOBILIZON_DATABASE_DBNAME -h $MOBILIZON_DATABASE_HOST -p ${MOBILIZON_DATABASE_PORT:-5432} -c 'CREATE EXTENSION IF NOT EXISTS unaccent;'

echo "-- Running migrations..."
mix mobilizon.ecto.migrate

echo "-- Starting Phoenix server!"
exec mix phx.server 