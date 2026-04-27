How to set up the Forms Service client key (required once per environment)
The Forms Service (pragmatic-forms) uses a two-level auth model:
- Admin key (FORMS_ADMIN_API_KEY) — only for managing clients
- Client key (FORMS_SERVICE_API_KEY) — used by the adapter for all form operations

After a fresh start (new machine, wiped volumes, or first checkout), the Client table
in forms-db is empty. Without a registered client the adapter cannot save or read
survey schemas and the whole survey gate silently fails.

Run this once after `make start` or `make start-local-forms`:

  CLIENT_JSON=$(docker exec pragmatic_forms_adapter \
    wget -qO- \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $(grep FORMS_ADMIN_API_KEY .env | cut -d= -f2)" \
    --post-data '{"name": "mobilizon-adapter"}' \
    http://forms-api:3000/clients)
  echo "$CLIENT_JSON"

Copy the `api_key` value from the output, then update .env:

  FORMS_SERVICE_API_KEY=<paste api_key here>

Restart the adapter to pick up the new key:

  docker compose --env-file .env \
    -f docker/development/docker-compose.yml \
    -f docker/development/docker-compose.local-forms.yml \
    up -d --force-recreate mobilizon-adapter

You only need to do this once per environment. The key survives container restarts
as long as the forms-db volume is not wiped. If you run `docker volume prune` or
recreate the forms-db volume, repeat the steps above.

How to cleanup database
1. ssh-add ~/.ssh/id_rsa
2. ssh root@161.35.26.157 -A
3. docker ps -a
4. docker exec -it postgis_container_id sh
5. psql -h postgres -U mobilizon (and type password)
6. copy pase code from database_cleanup.sh

How to add administator (via SQL)
1. ssh-add ~/.ssh/id_rsa
2. ssh root@161.35.26.157 -A
3. docker ps -a
4. docker exec -it postgis_container_id sh
5. psql -h postgres -U mobilizon (and type password)
6. SELECT role, email FROM users;
7. UPDATE users SET role = 'administrator' WHERE email = 'email@example.com';


Important: For now mix commands does work ONLY for local environment. For dev/prod db changes you need to write sql queries and execute them directly

How to create a new user in Docker development environment
1. cd docker/development
2. docker compose exec api mix mobilizon.users.new email@example.com --password YourPassword123 --admin

Example (create admin user):
  docker compose exec api mix mobilizon.users.new admin@example.com --password Pass123 --admin

How to create a new user (via mix task - native local)
1. mix mobilizon.users.new email@example.com --password YourPassword123

Options:
  --password, -p          Set the password (random if not provided)
  --admin                 Make the user an administrator
  --moderator             Make the user a moderator
  --profile_username      Create a profile with this username
  --profile_display_name  Set the profile display name

Examples:
  # Create admin user with profile
  mix mobilizon.users.new admin@example.com --password SecurePass123 --admin --profile_username admin --profile_display_name "Admin User"

  # Create regular user
  mix mobilizon.users.new user@example.com --password UserPass123

How to modify an existing user (via mix task)
  # Promote to admin
  mix mobilizon.users.modify email@example.com --admin

  # Change password
  mix mobilizon.users.modify email@example.com --password NewPassword123

  # Disable user
  mix mobilizon.users.modify email@example.com --disable

How to start application inside dev container
1. run project in devcontainer (/.devcontainer)
2. ./scripts/dev-start.sh

How to stop application inside dev container
1. run project in devcontainer (/.devcontainer)
2. ./scripts/dev-stop.sh
