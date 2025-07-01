init:
	@bash docker/message.sh "Start"
	make start

setup: stop
	@bash docker/message.sh "Compiling everything"
	docker compose -f docker/development/docker-compose.yml run --rm api bash -c 'mix deps.get; npm ci; npm run build:pictures; mix ecto.create; mix ecto.migrate'
migrate:
	docker compose -f docker/development/docker-compose.yml run --rm api mix ecto.migrate
logs:
	docker compose -f docker/development/docker-compose.yml logs -f
start: stop
	@bash docker/message.sh "Starting Mobilizon with Docker"
	docker compose -f docker/development/docker-compose.yml up -d api
	@bash docker/message.sh "Docker server started"
stop:
	@bash docker/message.sh "Stopping Mobilizon"
	docker compose -f docker/development/docker-compose.yml down
	@bash docker/message.sh "Mobilizon is stopped"
test: stop
	@bash docker/message.sh "Running tests"
	docker compose -f docker/development/docker-compose.yml -f docker/testing/docker-compose.yml run api mix prepare_test
	docker compose -f docker/development/docker-compose.yml -f docker/testing/docker-compose.yml run api mix test $(only)
	@bash docker/message.sh "Done running tests"
format: 
	docker compose -f docker/development/docker-compose.yml run --rm api bash -c "mix format && mix credo --strict"
	@bash docker/message.sh "Code is now ready to commit :)"
target: init
