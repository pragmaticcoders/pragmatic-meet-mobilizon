import Config

# Production configuration
# Note: For Docker deployments, this file is not used directly.
# Docker deployments use config/docker.exs as runtime.exs

# Basic endpoint configuration (will be overridden by environment variables in Docker)
config :mobilizon, Mobilizon.Web.Endpoint,
  server: true,
  http: [
    port: String.to_integer(System.get_env("MOBILIZON_INSTANCE_PORT", "4000"))
  ],
  url: [
    host: System.get_env("MOBILIZON_INSTANCE_HOST", "localhost"),
    scheme: System.get_env("MOBILIZON_INSTANCE_SCHEME", "http"),
    port: String.to_integer(System.get_env("MOBILIZON_INSTANCE_PORT", "4000"))
  ],
  secret_key_base: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY_BASE", "changethis")

# Database configuration (will be overridden by environment variables in Docker)
config :mobilizon, Mobilizon.Storage.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME", "mobilizon"),
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD", "mobilizon"),
  database: System.get_env("MOBILIZON_DATABASE_DBNAME", "mobilizon"),
  hostname: System.get_env("MOBILIZON_DATABASE_HOST", "localhost"),
  port: String.to_integer(System.get_env("MOBILIZON_DATABASE_PORT", "5432")),
  ssl: System.get_env("MOBILIZON_DATABASE_SSL", "false") == "true",
  pool_size: 10

# Instance configuration (will be overridden by environment variables in Docker)
config :mobilizon, :instance,
  name: System.get_env("MOBILIZON_INSTANCE_NAME", "Mobilizon"),
  description: System.get_env("MOBILIZON_INSTANCE_DESCRIPTION", "A Mobilizon instance"),
  hostname: System.get_env("MOBILIZON_INSTANCE_HOST", "localhost"),
  registrations_open: System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_OPEN", "false") == "true",
  default_language: System.get_env("MOBILIZON_INSTANCE_DEFAULT_LANGUAGE", "en"),
  federating: System.get_env("MOBILIZON_INSTANCE_FEDERATING", "true") == "true",
  email_from: System.get_env("MOBILIZON_INSTANCE_EMAIL", "noreply@localhost")

# SMTP configuration (will be overridden by environment variables in Docker)
config :mobilizon, Mobilizon.Web.Email.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("MOBILIZON_SMTP_SERVER"),
  port: String.to_integer(System.get_env("MOBILIZON_SMTP_PORT")),
  username: System.get_env("MOBILIZON_SMTP_USERNAME", nil),
  password: System.get_env("MOBILIZON_SMTP_PASSWORD", nil),
  tls: System.get_env("MOBILIZON_SMTP_TLS", "if_available"),
  auth: System.get_env("MOBILIZON_SMTP_AUTH", "if_available"),
  ssl: System.get_env("MOBILIZON_SMTP_SSL", "false"),
  retries: 1,
  no_mx_lookups: false
# Do not print debug messages in production
config :logger, level: :info

# Load all locales in production
config :mobilizon, :cldr,
  locales: [
    "pl",
    "en"
  ]

# Security configuration
config :mobilizon, Mobilizon.Web.Auth.Guardian,
  secret_key: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY", "changethis")

# Upload configuration
config :mobilizon, Mobilizon.Web.Upload.Uploader.Local,
  uploads: System.get_env("MOBILIZON_UPLOADS", "/var/lib/mobilizon/uploads")

# Timezone configuration
config :tz_world,
  data_dir: System.get_env("MOBILIZON_TIMEZONES_DIR", "/var/lib/mobilizon/timezones")

config :tzdata, :data_dir, System.get_env("MOBILIZON_TZDATA_DIR", "/var/lib/mobilizon/tzdata")

# Export configuration
config :mobilizon, :exports,
  path: System.get_env("MOBILIZON_UPLOADS_EXPORTS", "/var/lib/mobilizon/uploads/exports"),
  formats: [
    Mobilizon.Service.Export.Participants.CSV,
    Mobilizon.Service.Export.Participants.PDF,
    Mobilizon.Service.Export.Participants.ODS
  ]
