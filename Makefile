COMPOSE       = docker compose --env-file .env -f docker/development/docker-compose.yml
COMPOSE_LOCAL = docker compose --env-file .env \
  -f docker/development/docker-compose.yml \
  -f docker/development/docker-compose.local-forms.yml

init:
	@bash docker/message.sh "Building API container"
	$(COMPOSE) build
	@bash docker/message.sh "Start"
	make start

setup: stop
	@bash docker/message.sh "Compiling everything"
	$(COMPOSE) run --rm api bash -c 'mix deps.get; npm ci; npm run build:pictures; mix ecto.create; mix ecto.migrate'
migrate:
	$(COMPOSE) run --rm api mix ecto.migrate
logs:
	$(COMPOSE) logs -f

# Prerequisites for `make start`:
#   GITHUB_PAT and PRAGMATIC_FORMS_REPO must be set in .env (see .env.template)
#   GITHUB_PAT: GitHub Personal Access Token with repo (read) scope
start: stop
	@bash docker/message.sh "Starting Mobilizon with Docker"
	$(COMPOSE) up -d api
	@bash docker/message.sh "Docker server started"

# Pull latest pragmatic-forms code from GitHub and restart adapter services.
# Use after merging changes to the pragmatic-forms repo.
# --no-cache forces a fresh git clone, bypassing Docker's build cache.
update-adapter: stop
	@bash docker/message.sh "Rebuilding adapter from latest pragmatic-forms"
	$(COMPOSE) build --no-cache mobilizon-adapter adapter-nginx
	$(COMPOSE) up -d api
	@bash docker/message.sh "Docker server started"

# Rebuild adapter-nginx from LOCAL pragmatic-forms (no git clone needed).
# Use when working on builder.html or frontend assets with start-local-forms.
# Requires: pragmatic-forms repo must be a sibling directory of this repo.
update-adapter-local: stop
	@bash docker/message.sh "Rebuilding adapter-nginx from local pragmatic-forms"
	$(COMPOSE_LOCAL) build --no-cache mobilizon-adapter adapter-nginx
	$(COMPOSE_LOCAL) up -d api
	@bash docker/message.sh "Docker server started"

# Use when actively developing pragmatic-forms locally (hot-reload via bind mounts).
# No SSH key needed — uses local source directly.
# Requires: pragmatic-forms repo must be a sibling directory of this repo.
start-local-forms: stop
	@bash docker/message.sh "Starting Mobilizon with local pragmatic-forms"
	$(COMPOSE_LOCAL) up -d api
	@bash docker/message.sh "Docker server started"

stop:
	@bash docker/message.sh "Stopping Mobilizon"
	$(COMPOSE) down
	@bash docker/message.sh "Mobilizon is stopped"
test: stop
	@bash docker/message.sh "Running tests"
	$(COMPOSE) -f docker/testing/docker-compose.yml run api mix prepare_test
	$(COMPOSE) -f docker/testing/docker-compose.yml run api mix test $(only)
	@bash docker/message.sh "Done running tests"
format: 
	$(COMPOSE) run --rm api bash -c "mix format && mix credo --strict"
	@bash docker/message.sh "Code is now ready to commit :)"
target: init
