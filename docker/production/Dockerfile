# First build the application assets
FROM node:20-alpine as assets

RUN apk add --no-cache python3 build-base libwebp-tools bash imagemagick ncurses
WORKDIR /build
COPY . .

# Network timeout because it's slow when cross-compiling
# Skip prepare script (husky) in production builds, but run postinstall for patches
RUN npm ci --ignore-scripts
RUN npx patch-package
RUN npm run build

# Then, build the application binary
FROM elixir:1.16-alpine AS builder

# Fix qemu segfault on arm64
# See https://github.com/plausible/analytics/pull/2879 and https://github.com/erlang/otp/pull/6340
ARG ERL_FLAGS=""
ENV ERL_FLAGS=$ERL_FLAGS

RUN apk add --no-cache build-base git cmake

COPY mix.exs mix.lock ./
ENV MIX_ENV=prod
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get

COPY lib ./lib
COPY priv ./priv
COPY config/config.exs config/prod.exs ./config/
COPY config/docker.exs ./config/runtime.exs
COPY rel ./rel
COPY support ./support
COPY scripts ./scripts
COPY --from=assets /build/priv/static ./priv/static

RUN mix phx.digest.clean --all && mix phx.digest && mix release

# Finally setup the app
FROM alpine

ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.title="mobilizon" \
    org.opencontainers.image.description="Mobilizon for Docker" \
    org.opencontainers.image.vendor="joinmobilizon.org" \
    org.opencontainers.image.documentation="https://docs.joinmobilizon.org" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.source="https://framagit.org/framasoft/mobilizon" \
    org.opencontainers.image.url="https://joinmobilizon.org" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

RUN apk add --no-cache curl openssl ca-certificates ncurses-libs file postgresql-client libgcc libstdc++ imagemagick python3 py3-pip py3-pillow py3-cffi py3-brotli gcc g++ musl-dev python3-dev pango libxslt-dev ttf-cantarell
RUN pip --no-cache-dir install --break-system-packages weasyprint pyexcel-ods3

# Create every data directory
RUN mkdir -p /var/lib/mobilizon/uploads && chown nobody:nobody /var/lib/mobilizon/uploads
RUN mkdir -p /var/lib/mobilizon/timezones && chown nobody:nobody /var/lib/mobilizon/timezones
RUN mkdir -p /var/lib/mobilizon/tzdata && chown nobody:nobody /var/lib/mobilizon/tzdata
RUN mkdir -p /var/lib/mobilizon/sitemap && chown nobody:nobody /var/lib/mobilizon/sitemap
RUN mkdir -p /var/lib/mobilizon/uploads/exports/{csv,pdf,ods} && chown -R nobody:nobody /var/lib/mobilizon/uploads/exports

# Create configuration directory
RUN mkdir -p /etc/mobilizon && chown nobody:nobody /etc/mobilizon

# Copy and set permissions for mobilizon-admin (must be done as root)
COPY docker/production/mobilizon-admin /usr/local/bin/
RUN chmod +x /usr/local/bin/mobilizon-admin

USER nobody

EXPOSE 4000

ENV MOBILIZON_DOCKER=true
ENV MOBILIZON_CONFIG_PATH=/etc/mobilizon/config.exs

COPY --from=builder --chown=nobody:nobody _build/prod/rel/mobilizon ./
RUN cp /releases/*/runtime.exs /etc/mobilizon/config.exs
# Fix execute permissions on mobilizon_ctl script
RUN chmod +x /bin/mobilizon_ctl
COPY --chown=nobody:nobody docker/production/docker-entrypoint.sh ./
RUN chmod +x ./docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]
