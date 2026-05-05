# Build identity — declared globally so each FROM stage can opt in via
# bare `ARG VCS_REF` / `ARG BUILD_DATE`. Kept here as a single source so
# the value reaches both the Vite build (frontend bundle) and the Elixir
# release (VersionController serves /version.json with the same SHA).
ARG VCS_REF=dev
ARG BUILD_DATE=unknown

# First build the application assets
FROM node:20-alpine as assets

# Re-import the global ARGs and expose them as VITE_* env vars so
# vite.config.js can bake them into __GIT_COMMIT__ / __BUILD_TIME__.
ARG VCS_REF
ARG BUILD_DATE
ENV VITE_GIT_COMMIT=$VCS_REF
ENV VITE_BUILD_TIME=$BUILD_DATE

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

# Re-import the global ARGs. VersionController reads VITE_GIT_COMMIT and
# VITE_BUILD_TIME at *compile time* via System.get_env, so they must be
# present in the env when `mix release` runs below.
ARG VCS_REF
ARG BUILD_DATE
ENV VITE_GIT_COMMIT=$VCS_REF
ENV VITE_BUILD_TIME=$BUILD_DATE

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

RUN apk add --no-cache bash curl openssl ca-certificates ncurses-libs file postgresql-client libgcc libstdc++ imagemagick python3 py3-pip py3-pillow py3-cffi py3-brotli gcc g++ musl-dev python3-dev pango libxslt-dev ttf-cantarell
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

# `Mobilizon.Web.VersionController` reads these at runtime to answer
# /version.json. Setting them here means the running container reports
# the same SHA the JS bundle was built with — without depending on the
# release-time module attribute that wouldn't survive a future env
# change. Default to "dev" / "unknown" if the build skipped passing
# them; the SPA's version-check loop guard handles the sentinel safely.
ENV VITE_GIT_COMMIT=$VCS_REF
ENV VITE_BUILD_TIME=$BUILD_DATE

COPY --from=builder --chown=nobody:nobody _build/prod/rel/mobilizon ./
# Copy e2e seed file for e2e testing
COPY --chown=nobody:nobody priv/repo/e2e.seed.exs ./priv/repo/e2e.seed.exs
# Copy scripts directory for migration scripts
COPY --chown=nobody:nobody scripts ./scripts
RUN chmod +x ./scripts/*.sh
RUN cp /releases/*/runtime.exs /etc/mobilizon/config.exs
# Fix execute permissions on mobilizon_ctl script
RUN chmod +x /bin/mobilizon_ctl
COPY --chown=nobody:nobody docker/production/docker-entrypoint.sh ./
RUN chmod +x ./docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]
