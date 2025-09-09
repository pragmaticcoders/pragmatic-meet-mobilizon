How to cleanup database
1. ssh-add ~/.ssh/id_rsa
2. ssh root@161.35.26.157 -A
3. docker ps -a
4. docker exec -it postgis_container_id sh
5. psql -h postgres -U mobilizon (and type password)
6. copy pase code from database_cleanup.sh

How to add administator
1. ssh-add ~/.ssh/id_rsa
2. ssh root@161.35.26.157 -A
3. docker ps -a
4. docker exec -it postgis_container_id sh
5. psql -h postgres -U mobilizon (and type password)
6. SELECT role, email FROM users;
7. UPDATE users SET role = 'administrator' WHERE email = 'email@example.com';


How to start application inside dev container
1. run project in devcontainer (/.devcontainer)
2. ./scripts/dev-start.sh

How to stop application inside dev container
1. run project in devcontainer (/.devcontainer)
2. ./scripts/dev-stop.sh