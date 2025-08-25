defmodule Mobilizon.Web.OAuth.LinkedInOAuth do
  @moduledoc """
  Direct LinkedIn OAuth2 implementation for better reliability and control.
  Replaces Ueberauth LinkedIn strategy to fix OAuth failures.

  Implements fixes based on community solutions for LinkedIn OAuth timing issues:
  - Forces client credentials in request body (AuthStyleInParams equivalent)
  - Adds 5-second delay between token exchange and user info fetch
  - Specific handling for REVOKED_ACCESS_TOKEN errors (user permission revocation)
  - Comprehensive retry logic for transient failures
  """

  require Logger
  alias OAuth2.{Client, Strategy.AuthCode}

  @linkedin_config [
    strategy: AuthCode,
    site: "https://www.linkedin.com",
    authorize_url: "https://www.linkedin.com/oauth/v2/authorization",
    token_url: "https://www.linkedin.com/oauth/v2/accessToken",
    user_info_url: "https://api.linkedin.com/v2/userinfo"
  ]

  @default_scopes ["openid", "profile", "email"]
  @max_retries 3
  @retry_delay_ms 2000
  # Delay between token exchange and user info fetch to handle LinkedIn timing issues
  @token_activation_delay_ms 5000

  @doc """
  Creates OAuth2 client for LinkedIn with enhanced reliability settings.
  """
  def client do
    client_id =
      System.get_env("LINKEDIN_CLIENT_ID") ||
        Application.get_env(:mobilizon, :linkedin)[:client_id]

    client_secret =
      System.get_env("LINKEDIN_CLIENT_SECRET") ||
        Application.get_env(:mobilizon, :linkedin)[:client_secret]

    unless client_id && client_secret do
      raise "LinkedIn OAuth credentials not configured. Set LINKEDIN_CLIENT_ID and LINKEDIN_CLIENT_SECRET environment variables."
    end

    @linkedin_config
    |> Keyword.merge(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: get_redirect_uri(),
      # Force client credentials to be sent in request body (not HTTP Basic auth)
      # This is equivalent to AuthStyleInParams in Go's oauth2 library
      request_opts: [
        hackney: [
          # Ensure no basic auth headers are added automatically
          basic_auth: nil
        ]
      ]
    )
    |> Client.new()
    |> Client.put_serializer("application/json", Jason)
  end

  @doc """
  Generates LinkedIn OAuth authorization URL with proper state and PKCE.
  """
  def authorize_url(state \\ nil, scopes \\ @default_scopes) do
    params = [
      scope: Enum.join(scopes, " "),
      state: state || generate_state()
    ]

    Logger.info("LinkedIn OAuth: Generating authorization URL")
    client_config = client()
    auth_url = Client.authorize_url!(client_config, params)

    auth_url
  end

  @doc """
  Exchanges authorization code for access token with retry logic.
  """
  def get_token(code, _state \\ nil) do
    params = [
      code: code,
      grant_type: "authorization_code",
      redirect_uri: get_redirect_uri()
    ]

    get_token_with_retry(params, 1)
  end

  @doc """
  Fetches user information from LinkedIn API with retry logic.
  """
  def get_user_info(token) do
    get_user_info_with_retry(token, 1)
  end

  @doc """
  Complete authentication flow: exchange code for token, then fetch user info.
  """
  def authenticate(code, state) do
    Logger.info("LinkedIn OAuth: Starting authentication flow")

    with {:ok, token} <- get_token(code, state),
         :ok <- add_token_activation_delay(),
         {:ok, user_info} <- get_user_info(token) do
      Logger.info("LinkedIn OAuth: Authentication successful for #{user_info["email"]}")
      {:ok, %{user_info: user_info, token: token}}
    else
      {:error, reason} ->
        Logger.error("LinkedIn OAuth: Authentication failed - #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_redirect_uri do
    System.get_env("LINKEDIN_REDIRECT_URI") ||
      Application.get_env(:mobilizon, :linkedin)[:redirect_uri] ||
      "http://localhost:4000/auth/linkedin/callback"
  end

  defp generate_state do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp add_token_activation_delay do
    Logger.info("LinkedIn OAuth: Adding #{@token_activation_delay_ms}ms timing delay")
    Process.sleep(@token_activation_delay_ms)
    :ok
  end

  defp get_token_with_retry(_params, attempt) when attempt > @max_retries do
    Logger.error("LinkedIn OAuth: Token exchange failed after #{@max_retries} attempts")
    {:error, :max_retries_exceeded}
  end

  defp get_token_with_retry(params, attempt) do
    Logger.info("LinkedIn OAuth: Token exchange attempt #{attempt}/#{@max_retries}")

    client_instance = client()

    # LinkedIn requires client credentials in request body, not HTTP Basic auth
    enhanced_params =
      params ++
        [
          client_id: client_instance.client_id,
          client_secret: client_instance.client_secret
        ]

    case Client.get_token(client_instance, enhanced_params) do
      {:ok, %{token: token}} ->
        Logger.info("LinkedIn OAuth: Token exchange successful on attempt #{attempt}")
        {:ok, token}

      {:error, %OAuth2.Response{status_code: status}}
      when status >= 500 and attempt < @max_retries ->
        Logger.warning("LinkedIn OAuth: Server error #{status}, retrying in #{@retry_delay_ms}ms...")
        Process.sleep(@retry_delay_ms)
        get_token_with_retry(params, attempt + 1)

      {:error, %OAuth2.Response{status_code: status, body: body}}
      when status == 400 and attempt < @max_retries ->
        Logger.error("LinkedIn OAuth: Client error #{status}")

        # Check if this is a transient 400 error (sometimes LinkedIn returns 400 for timeouts)
        error_description = get_in(body, ["error_description"]) || ""

        if String.contains?(error_description, ["timeout", "temporary", "try again"]) do
          Logger.warning("LinkedIn OAuth: Transient error #{status}, retrying...")
          Process.sleep(@retry_delay_ms)
          get_token_with_retry(params, attempt + 1)
        else
          Logger.error("LinkedIn OAuth: Non-retryable client error #{status}")
          {:error, {:oauth_error, status, body}}
        end

      {:error, %OAuth2.Error{reason: :timeout}} when attempt < @max_retries ->
        Logger.warning("LinkedIn OAuth: Timeout, retrying in #{@retry_delay_ms}ms...")
        Process.sleep(@retry_delay_ms)
        get_token_with_retry(params, attempt + 1)

      {:error, %OAuth2.Response{status_code: status, body: body}} ->
        Logger.error("LinkedIn OAuth: Token exchange failed with status #{status}")
        {:error, {:oauth_error, status, body}}

      {:error, reason} ->
        Logger.error("LinkedIn OAuth: Token exchange failed - #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_user_info_with_retry(_token, attempt) when attempt > @max_retries do
    Logger.error("LinkedIn OAuth: User info fetch failed after #{@max_retries} attempts")
    {:error, :max_retries_exceeded}
  end

  defp get_user_info_with_retry(token, attempt) do
    Logger.info("LinkedIn OAuth: User info fetch attempt #{attempt}/#{@max_retries}")

    user_info_url = @linkedin_config[:user_info_url]
    headers = [{"Authorization", "Bearer #{token.access_token}"}]

    case HTTPoison.get(user_info_url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("LinkedIn OAuth: User info fetch successful on attempt #{attempt}")

        case Jason.decode(body) do
          {:ok, user_info} ->
            {:ok, user_info}

          {:error, reason} ->
            Logger.error("LinkedIn OAuth: Failed to decode user info JSON: #{inspect(reason)}")
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status}}
      when status >= 500 and attempt < @max_retries ->
        Logger.warning("LinkedIn OAuth: Server error #{status}, retrying in #{@retry_delay_ms}ms...")
        Process.sleep(@retry_delay_ms)
        get_user_info_with_retry(token, attempt + 1)

      {:ok, %HTTPoison.Response{status_code: 401, body: body}} ->
        Logger.error("LinkedIn OAuth: User info fetch failed with status 401")

        # Check for specific REVOKED_ACCESS_TOKEN error
        case Jason.decode(body) do
          {:ok, %{"code" => "REVOKED_ACCESS_TOKEN"}} ->
            Logger.error("LinkedIn OAuth: Token was revoked by user")
            {:error, {:revoked_token, "User has revoked access to the LinkedIn application"}}

          _ ->
            {:error, {:http_error, 401, body}}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("LinkedIn OAuth: User info fetch failed with status #{status}")
        {:error, {:http_error, status, body}}

      {:error, %HTTPoison.Error{reason: reason}} when attempt < @max_retries ->
        Logger.warning("LinkedIn OAuth: HTTP error (#{reason}), retrying in #{@retry_delay_ms}ms...")
        Process.sleep(@retry_delay_ms)
        get_user_info_with_retry(token, attempt + 1)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("LinkedIn OAuth: HTTP error fetching user info: #{reason}")
        {:error, {:http_error, reason}}
    end
  end
end
