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
  relay: System.get_env("MOBILIZON_SMTP_SERVER", "email-smtp.eu-central-1.amazonaws.com"),
  port: String.to_integer(System.get_env("MOBILIZON_SMTP_PORT", "587")),
  username: System.get_env("MOBILIZON_SMTP_USERNAME"),
  password: System.get_env("MOBILIZON_SMTP_PASSWORD"),
  tls: System.get_env("MOBILIZON_SMTP_TLS", "always"),
  auth: System.get_env("MOBILIZON_SMTP_AUTH", "always"),
  ssl: System.get_env("MOBILIZON_SMTP_SSL", "false"),
  tls_options: [
    verify: :verify_none,
    versions: [:"tlsv1.2"],
    ciphers: :ssl.cipher_suites(:default, :"tlsv1.2")
  ],
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

# OAuth Configuration

config :ueberauth,
       Ueberauth,
       providers: [
         # LinkedIn now uses direct OAuth2 implementation for better reliability
         # linkedin: {Ueberauth.Strategy.LinkedIn, []}
         # Add other providers here as needed:
         # google: {Ueberauth.Strategy.Google, []},
         # github: {Ueberauth.Strategy.Github, []},
         # facebook: {Ueberauth.Strategy.Facebook, []},
         # discord: {Ueberauth.Strategy.Discord, []},
         # gitlab: {Ueberauth.Strategy.Gitlab, [default_scope: "read_user"]},
         # twitter: {Ueberauth.Strategy.Twitter, []},
         # keycloak: {UeberauthKeycloakStrategy.Strategy, [default_scope: "openid email"]}
       ]

config :mobilizon, :auth,
  oauth_consumer_strategies: [
    # Still supported via direct OAuth2 implementation
    :linkedin
    # {:linkedin, "LinkedIn"}  # Use this format for custom labels
    # :google,
    # :github,
    # :facebook,
    # :discord,
    # :gitlab,
    # :twitter,
    # {:keycloak, "My corporate account"}
  ]

# Direct LinkedIn OAuth2 configuration (replaces Ueberauth LinkedIn)
config :mobilizon, :linkedin,
  client_id: System.get_env("LINKEDIN_CLIENT_ID"),
  client_secret: System.get_env("LINKEDIN_CLIENT_SECRET"),
  redirect_uri:
    System.get_env(
      "LINKEDIN_REDIRECT_URI",
      "https://pragmaticmeet.com/auth/linkedin/callback"
    )

# HTTP client configuration for OAuth requests
config :oauth2, :http_client, HTTPoison

# HTTPoison configuration with better timeout handling
config :httpoison,
  timeout: 30_000,
  recv_timeout: 30_000,
  hackney: [
    timeout: 30_000,
    recv_timeout: 30_000,
    pool_timeout: 10_000,
    max_connections: 50,
    # Additional reliability options
    retry: 3,
    retry_delay: 1000,
    follow_redirect: true,
    max_redirect: 3,
    # Connection pool options
    pool: :oauth_pool
  ]
