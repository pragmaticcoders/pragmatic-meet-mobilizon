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
How to create a new user (via mix task)
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
