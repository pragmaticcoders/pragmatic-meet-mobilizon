FORMS_IMAGE_TAG := $(shell cat forms-image-tag 2>/dev/null | tr -d '[:space:]' || echo latest)

COMPOSE       = FORMS_IMAGE_TAG=$(FORMS_IMAGE_TAG) docker compose --env-file .env -f docker/development/docker-compose.yml
COMPOSE_LOCAL = FORMS_IMAGE_TAG=$(FORMS_IMAGE_TAG) docker compose --env-file .env \
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

# Default mode: pulls forms images from ghcr.io (same images as production).
# Tag is read from forms-image-tag file at the repo root.
#
# Prerequisites (once per machine):
#   docker login ghcr.io -u <USERNAME> --password-stdin   # PAT with read:packages
start: stop
	@bash docker/message.sh "Starting Mobilizon (forms images: $(FORMS_IMAGE_TAG))"
	$(COMPOSE) up -d api
	@bash docker/message.sh "Docker server started"

# Pull the latest forms images from ghcr.io without restarting Mobilizon.
# Use to refresh adapter/nginx/forms-api after bumping forms-image-tag.
pull-forms:
	@bash docker/message.sh "Pulling forms images: $(FORMS_IMAGE_TAG)"
	$(COMPOSE) pull mobilizon-adapter adapter-nginx forms-api
	$(COMPOSE) up -d --force-recreate mobilizon-adapter adapter-nginx forms-api
	@bash docker/message.sh "Forms images updated"

# Use when actively developing pragmatic-forms locally (hot-reload via bind mounts).
# Builds adapter/forms from local sibling pragmatic-forms repo instead of pulling from ghcr.io.
# Requires: pragmatic-forms repo must be a sibling directory of this repo.
start-local-forms: stop
	@bash docker/message.sh "Starting Mobilizon with local pragmatic-forms"
	$(COMPOSE_LOCAL) build forms-api mobilizon-adapter adapter-nginx
	$(COMPOSE_LOCAL) up -d api
	@bash docker/message.sh "Docker server started"

# Rebuild adapter from local pragmatic-forms checkout (with start-local-forms).
update-adapter-local: stop
	@bash docker/message.sh "Rebuilding adapter from local pragmatic-forms"
	$(COMPOSE_LOCAL) build --no-cache mobilizon-adapter adapter-nginx
	$(COMPOSE_LOCAL) up -d api
	@bash docker/message.sh "Docker server started"

# Rebuild only forms-api from local pragmatic-forms checkout (with start-local-forms).
# Use after changes to forms/Dockerfile or when forms-api fails to start.
update-forms-local: stop
	@bash docker/message.sh "Rebuilding forms-api from local pragmatic-forms"
	$(COMPOSE_LOCAL) build --no-cache forms-api
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
