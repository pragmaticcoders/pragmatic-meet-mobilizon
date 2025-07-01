FROM elixir:1.15-alpine

RUN apk add --no-cache inotify-tools postgresql-client file make gcc libc-dev argon2 imagemagick cmake build-base libwebp-tools bash ncurses git python3 npm

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /workspace

COPY docker/development/docker-entrypoint.sh /usr/local/bin/
COPY docker/development/docker-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-setup.sh

EXPOSE 4000
EXPOSE 5173

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"] 