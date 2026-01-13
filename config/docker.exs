# Mobilizon instance configuration

import Config
import Mobilizon.Service.Config.Helpers

{:ok, _} = Application.ensure_all_started(:tls_certificate_check)

loglevels = [
  :emergency,
  :alert,
  :critical,
  :error,
  :warning,
  :notice,
  :info,
  :debug
]

loglevel_env = System.get_env("MOBILIZON_LOGLEVEL", "error")

loglevel =
  if loglevel_env in Enum.map(loglevels, &to_string/1) do
    String.to_existing_atom(loglevel_env)
  else
    :error
  end

listen_ip = System.get_env("MOBILIZON_INSTANCE_LISTEN_IP", "0.0.0.0")

listen_ip =
  case listen_ip |> to_charlist() |> :inet.parse_address() do
    {:ok, listen_ip} -> listen_ip
    _ -> raise "MOBILIZON_INSTANCE_LISTEN_IP does not match the expected IP format."
  end

config :mobilizon, Mobilizon.Web.Endpoint,
  server: true,
  url: [
    host: System.get_env("MOBILIZON_INSTANCE_HOST", "mobilizon.lan"),
    scheme: System.get_env("MOBILIZON_INSTANCE_SCHEME", "https"),
    port:
      case {System.get_env("MOBILIZON_INSTANCE_SCHEME", "https"),
            System.get_env("MOBILIZON_INSTANCE_EXTERNAL_PORT")} do
        # Default HTTPS port
        {"https", nil} -> 443
        # Default HTTP port
        {"http", nil} -> 80
        {_, port_str} when is_binary(port_str) -> String.to_integer(port_str)
        # Fallback to HTTPS default
        _ -> 443
      end
  ],
  http: [
    port: String.to_integer(System.get_env("MOBILIZON_INSTANCE_PORT", "4000")),
    ip: listen_ip
  ],
  secret_key_base: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY_BASE", "changethis")

config :mobilizon, Mobilizon.Web.Auth.Guardian,
  secret_key: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY", "changethis")

config :mobilizon, :instance,
  name: System.get_env("MOBILIZON_INSTANCE_NAME", "Mobilizon"),
  description: "Change this to a proper description of your instance",
  hostname: System.get_env("MOBILIZON_INSTANCE_HOST", "mobilizon.lan"),
  registrations_open: System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_OPEN", "false") == "true",
  registration_email_allowlist:
    System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_EMAIL_ALLOWLIST", "")
    |> String.split(",", trim: true),
  registration_email_denylist:
    System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_EMAIL_DENYLIST", "")
    |> String.split(",", trim: true),
  disable_database_login:
    System.get_env("MOBILIZON_INSTANCE_DISABLE_DATABASE_LOGIN", "false") == "true",
  default_language: System.get_env("MOBILIZON_INSTANCE_DEFAULT_LANGUAGE", "en"),
  demo: System.get_env("MOBILIZON_INSTANCE_DEMO", "false") == "true",
  allow_relay: System.get_env("MOBILIZON_INSTANCE_ALLOW_RELAY", "true") == "true",
  federating: System.get_env("MOBILIZON_INSTANCE_FEDERATING", "true") == "true",
  enable_instance_feeds:
    System.get_env("MOBILIZON_INSTANCE_ENABLE_INSTANCE_FEEDS", "true") == "true",
  email_from: System.get_env("MOBILIZON_INSTANCE_EMAIL", "noreply@mobilizon.lan"),
  email_reply_to: System.get_env("MOBILIZON_REPLY_EMAIL", "noreply@mobilizon.lan")

config :mobilizon, Mobilizon.Storage.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME", "username"),
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD", "password"),
  database: System.get_env("MOBILIZON_DATABASE_DBNAME", "mobilizon"),
  hostname: System.get_env("MOBILIZON_DATABASE_HOST", "postgres"),
  port: System.get_env("MOBILIZON_DATABASE_PORT", "5432"),
  ssl: System.get_env("MOBILIZON_DATABASE_SSL", "false") == "true",
  pool_size: 10

config :logger, level: loglevel

config :mobilizon, Mobilizon.Web.Email.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("MOBILIZON_SMTP_SERVER", "localhost"),
  port: System.get_env("MOBILIZON_SMTP_PORT", "25"),
  username: System.get_env("MOBILIZON_SMTP_USERNAME", "test"),
  password: System.get_env("MOBILIZON_SMTP_PASSWORD", "test"),
  tls: System.get_env("MOBILIZON_SMTP_TLS", "if_available"),
  tls_options:
    :tls_certificate_check.options(System.get_env("MOBILIZON_SMTP_SERVER", "localhost")),
  ssl: System.get_env("MOBILIZON_SMTP_SSL", "false"),
  retries: 1,
  no_mx_lookups: false,
  auth: System.get_env("MOBILIZON_SMTP_AUTH", "if_available")

config :geolix,
  databases: [
    %{
      id: :city,
      adapter: Geolix.Adapter.MMDB2,
      source: "/var/lib/mobilizon/geo_db/GeoLite2-City.mmdb"
    }
  ]

config :mobilizon, Mobilizon.Web.Upload.Uploader.Local,
  uploads: System.get_env("MOBILIZON_UPLOADS", "/var/lib/mobilizon/uploads")

formats =
  if System.get_env("MOBILIZON_EXPORTS_FORMAT_CSV_ENABLED", "true") == "true" do
    [Mobilizon.Service.Export.Participants.CSV]
  else
    []
  end

formats =
  if System.get_env("MOBILIZON_EXPORTS_FORMAT_PDF_ENABLED", "true") == "true" do
    formats ++ [Mobilizon.Service.Export.Participants.PDF]
  else
    formats
  end

formats =
  if System.get_env("MOBILIZON_EXPORTS_FORMAT_ODS_ENABLED", "true") == "true" do
    formats ++ [Mobilizon.Service.Export.Participants.ODS]
  else
    formats
  end

config :mobilizon, :exports,
  path: System.get_env("MOBILIZON_UPLOADS_EXPORTS", "/var/lib/mobilizon/uploads/exports"),
  formats: formats

config :tz_world,
  data_dir: System.get_env("MOBILIZON_TIMEZONES_DIR", "/var/lib/mobilizon/timezones")

config :tzdata, :data_dir, System.get_env("MOBILIZON_TZDATA_DIR", "/var/lib/mobilizon/tzdata")

config :web_push_encryption, :vapid_details,
  subject: System.get_env("MOBILIZON_WEB_PUSH_ENCRYPTION_SUBJECT", nil),
  public_key: System.get_env("MOBILIZON_WEB_PUSH_ENCRYPTION_PUBLIC_KEY", nil),
  private_key: System.get_env("MOBILIZON_WEB_PUSH_ENCRYPTION_PRIVATE_KEY", nil)

geospatial_service =
  case System.get_env("MOBILIZON_GEOSPATIAL_SERVICE", "Nominatim") do
    "Nominatim" -> Mobilizon.Service.Geospatial.Nominatim
    "Addok" -> Mobilizon.Service.Geospatial.Addok
    "Photon" -> Mobilizon.Service.Geospatial.Photon
    "GoogleMaps" -> Mobilizon.Service.Geospatial.GoogleMaps
    "MapQuest" -> Mobilizon.Service.Geospatial.MapQuest
    "Mimirsbrunn" -> Mobilizon.Service.Geospatial.Mimirsbrunn
    "Pelias" -> Mobilizon.Service.Geospatial.Pelias
    "Hat" -> Mobilizon.Service.Geospatial.Hat
  end

config :mobilizon, Mobilizon.Service.Geospatial, service: geospatial_service

config :mobilizon, Mobilizon.Service.Geospatial.Nominatim,
  endpoint:
    System.get_env(
      "MOBILIZON_GEOSPATIAL_NOMINATIM_ENDPOINT",
      "https://nominatim.openstreetmap.org"
    ),
  api_key: System.get_env("MOBILIZON_GEOSPATIAL_NOMINATIM_API_KEY", nil)

config :mobilizon, Mobilizon.Service.Geospatial.Addok,
  endpoint:
    System.get_env("MOBILIZON_GEOSPATIAL_ADDOK_ENDPOINT", "https://api-adresse.data.gouv.fr")

config :mobilizon, Mobilizon.Service.Geospatial.Photon,
  endpoint: System.get_env("MOBILIZON_GEOSPATIAL_PHOTON_ENDPOINT", "https://photon.komoot.de")

config :mobilizon, Mobilizon.Service.Geospatial.GoogleMaps,
  api_key: System.get_env("MOBILIZON_GEOSPATIAL_GOOGLE_MAPS_API_KEY", nil),
  fetch_place_details: true

config :mobilizon, Mobilizon.Service.Geospatial.MapQuest,
  api_key: System.get_env("MOBILIZON_GEOSPATIAL_MAP_QUEST_API_KEY", nil)

config :mobilizon, Mobilizon.Service.Geospatial.Mimirsbrunn,
  endpoint: System.get_env("MOBILIZON_GEOSPATIAL_MIMIRSBRUNN_ENDPOINT", nil)

config :mobilizon, Mobilizon.Service.Geospatial.Pelias,
  endpoint: System.get_env("MOBILIZON_GEOSPATIAL_PELIAS_ENDPOINT", nil)

sentry_dsn = System.get_env("MOBILIZON_ERROR_REPORTING_SENTRY_DSN", nil)

included_environments = if sentry_dsn, do: ["prod"], else: []

config :sentry,
  dsn: sentry_dsn,
  included_environments: included_environments,
  release: to_string(Application.spec(:mobilizon, :vsn))

config :logger, Sentry.LoggerBackend,
  capture_log_messages: true,
  level: :error

if sentry_dsn != nil do
  config :mobilizon, Mobilizon.Service.ErrorReporting,
    adapter: Mobilizon.Service.ErrorReporting.Sentry
end

matomo_enabled = System.get_env("MOBILIZON_FRONT_END_ANALYTICS_MATOMO_ENABLED", "false") == "true"
matomo_endpoint = System.get_env("MOBILIZON_FRONT_END_ANALYTICS_MATOMO_ENDPOINT", nil)
matomo_site_id = System.get_env("MOBILIZON_FRONT_END_ANALYTICS_MATOMO_SITE_ID", nil)

matomo_tracker_file_name =
  System.get_env("MOBILIZON_FRONT_END_ANALYTICS_MATOMO_TRACKER_FILE_NAME", "matomo")

matomo_host = host_from_uri(matomo_endpoint)

analytics_providers =
  if matomo_enabled do
    [Mobilizon.Service.FrontEndAnalytics.Matomo]
  else
    []
  end

analytics_providers =
  if sentry_dsn != nil do
    analytics_providers ++ [Mobilizon.Service.FrontEndAnalytics.Sentry]
  else
    analytics_providers
  end

matomo_csp =
  if matomo_enabled and matomo_host do
    [
      connect_src: [matomo_host],
      script_src: [matomo_host],
      img_src: [matomo_host]
    ]
  else
    []
  end

config :mobilizon, Mobilizon.Service.FrontEndAnalytics.Matomo,
  enabled: matomo_enabled,
  host: matomo_endpoint,
  siteId: matomo_site_id,
  trackerFileName: matomo_tracker_file_name,
  csp: matomo_csp

config :mobilizon, Mobilizon.Service.FrontEndAnalytics.Sentry,
  enabled: sentry_dsn != nil,
  dsn: sentry_dsn,
  tracesSampleRate: 1.0,
  organization: System.get_env("MOBILIZON_ERROR_REPORTING_SENTRY_ORGANISATION", nil),
  project: System.get_env("MOBILIZON_ERROR_REPORTING_SENTRY_PROJECT", nil),
  host: System.get_env("MOBILIZON_ERROR_REPORTING_SENTRY_HOST", nil),
  csp: [
    connect_src:
      System.get_env("MOBILIZON_ERROR_REPORTING_SENTRY_HOST", "") |> String.split(" ", trim: true)
  ]

# Google Analytics Configuration
google_analytics_enabled =
  System.get_env("MOBILIZON_FRONT_END_ANALYTICS_GOOGLE_ENABLED", "false") == "true"

google_analytics_measurement_id =
  System.get_env("MOBILIZON_FRONT_END_ANALYTICS_GOOGLE_MEASUREMENT_ID", nil)

google_analytics_anonymize_ip =
  System.get_env("MOBILIZON_FRONT_END_ANALYTICS_GOOGLE_ANONYMIZE_IP", "true") == "true"

analytics_providers =
  if google_analytics_enabled and google_analytics_measurement_id do
    analytics_providers ++ [Mobilizon.Service.FrontEndAnalytics.GoogleAnalytics]
  else
    analytics_providers
  end

config :mobilizon, :analytics, providers: analytics_providers

config :mobilizon, Mobilizon.Service.FrontEndAnalytics.GoogleAnalytics,
  enabled: google_analytics_enabled,
  measurementId: google_analytics_measurement_id,
  anonymizeIp: google_analytics_anonymize_ip,
  sendPageView: true,
  csp: [
    connect_src: ["www.google-analytics.com", "www.googletagmanager.com", "region1.google-analytics.com"],
    script_src: ["www.googletagmanager.com"],
    img_src: ["www.google-analytics.com"]
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
  client_id: System.get_env("LINKEDIN_CLIENT_ID", "77es95oq72tify"),
  client_secret: System.get_env("LINKEDIN_CLIENT_SECRET", "WPL_AP1.okqW0Aw0MhW01D28.KX0ypw=="),
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

# Example configurations for other providers:
# config :ueberauth, Ueberauth.Strategy.Google.OAuth,
#   client_id: System.get_env("GOOGLE_CLIENT_ID"),
#   client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

# config :ueberauth, Ueberauth.Strategy.Github.OAuth,
#   client_id: System.get_env("GITHUB_CLIENT_ID"),
#   client_secret: System.get_env("GITHUB_CLIENT_SECRET")

# config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
#   client_id: System.get_env("FACEBOOK_CLIENT_ID"),
#   client_secret: System.get_env("FACEBOOK_CLIENT_SECRET")

# keycloak_url = System.get_env("KEYCLOAK_URL", "https://some-keycloak-instance.org")
# config :ueberauth, UeberauthKeycloakStrategy.Strategy.OAuth,
#   client_id: System.get_env("KEYCLOAK_CLIENT_ID"),
#   client_secret: System.get_env("KEYCLOAK_CLIENT_SECRET"),
#   site: keycloak_url,
#   authorize_url: "#{keycloak_url}/auth/realms/master/protocol/openid-connect/auth",
#   token_url: "#{keycloak_url}/auth/realms/master/protocol/openid-connect/token",
#   userinfo_url: "#{keycloak_url}/auth/realms/master/protocol/openid-connect/userinfo",
#   token_method: :post

# Content Security Policy configuration for media domain
media_host = System.get_env("MOBILIZON_INSTANCE_HOST", "mobilizon.lan")
media_port = System.get_env("MOBILIZON_INSTANCE_PORT", "4000")
media_scheme = System.get_env("MOBILIZON_INSTANCE_SCHEME", "https")

# Build media URL for CSP
media_url =
  if media_port in ["80", "443"] or
       (media_scheme == "http" and media_port == "80") or
       (media_scheme == "https" and media_port == "443") do
    media_host
  else
    "#{media_host}:#{media_port}"
  end

config :mobilizon, :http_security,
  enabled: true,
  sts: false,
  sts_max_age: 31_536_000,
  csp_policy: [
    script_src: [
      "https://consent.cookiebot.com",
      "https://consentcdn.cookiebot.com"
    ],
    style_src: [],
    connect_src: [
      "https://consentcdn.cookiebot.com",
      "https://consent.cookiebot.com"
    ],
    font_src: [],
    img_src: [
      "*.tile.openstreetmap.org",
      media_url,
      "meetup.pragmaticcoders.com",
      "pragmaticmeet.com",
      "dev.pragmaticmeet.com",
      "http://imgsct.cookiebot.com",
      "https://imgsct.cookiebot.com"
    ],
    manifest_src: [],
    media_src: [
      "meetup.pragmaticcoders.com",
      "pragmaticmeet.com",
      "dev.pragmaticmeet.com"
    ],
    object_src: [],
    frame_src: [
      "https://www.youtube.com",
      "https://www.youtube-nocookie.com",
      "https://youtu.be",
      "https://consentcdn.cookiebot.com"
    ],
    frame_ancestors: []
  ],
  referrer_policy: "same-origin"
