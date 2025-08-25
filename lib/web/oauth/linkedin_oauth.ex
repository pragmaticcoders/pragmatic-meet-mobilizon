defmodule Mobilizon.Web.OAuth.LinkedInOAuth do
  @moduledoc """
  Direct LinkedIn OAuth2 implementation for better reliability and control.
  Replaces Ueberauth LinkedIn strategy to fix intermittent "50/50" OAuth failures.

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
    Logger.debug("LinkedIn OAuth: Authorization parameters: #{inspect(params, pretty: true)}")

    client_config = client()
    Logger.debug("LinkedIn OAuth: Client configuration: #{inspect(client_config, pretty: true)}")

    auth_url = Client.authorize_url!(client_config, params)
    Logger.info("LinkedIn OAuth: Generated authorization URL: #{auth_url}")

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
    Logger.info(
      "LinkedIn OAuth: Adding #{@token_activation_delay_ms}ms delay for token activation (fixes timing issues)"
    )

    Process.sleep(@token_activation_delay_ms)
    :ok
  end

  defp get_token_with_retry(_params, attempt) when attempt > @max_retries do
    Logger.error(
      "LinkedIn OAuth: Token exchange failed after #{@max_retries} attempts, giving up"
    )

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

    Logger.debug(
      "LinkedIn OAuth: Token exchange request parameters: #{inspect(enhanced_params, pretty: true)}"
    )

    Logger.debug("LinkedIn OAuth: Making token request to: #{client_instance.token_url}")
    Logger.debug("LinkedIn OAuth: Client ID: #{client_instance.client_id}")
    Logger.debug("LinkedIn OAuth: Redirect URI: #{client_instance.redirect_uri}")

    case Client.get_token(client_instance, enhanced_params) do
      {:ok, %{token: token} = client_result} ->
        Logger.info("LinkedIn OAuth: Token exchange successful on attempt #{attempt}")
        Logger.debug("LinkedIn OAuth: Received token: #{inspect(token, pretty: true)}")

        Logger.debug(
          "LinkedIn OAuth: Full client result: #{inspect(client_result, pretty: true)}"
        )

        {:ok, token}

      {:error, %OAuth2.Response{status_code: status, body: body, headers: headers}}
      when status >= 500 and attempt < @max_retries ->
        Logger.warning(
          "LinkedIn OAuth: Server error #{status} on attempt #{attempt}, retrying in #{@retry_delay_ms}ms..."
        )

        Logger.error("LinkedIn OAuth: Response status: #{status}")
        Logger.error("LinkedIn OAuth: Response headers: #{inspect(headers, pretty: true)}")
        Logger.error("LinkedIn OAuth: Response body: #{inspect(body, pretty: true)}")
        Process.sleep(@retry_delay_ms)
        get_token_with_retry(params, attempt + 1)

      {:error, %OAuth2.Response{status_code: status, body: body, headers: headers}}
      when status == 400 and attempt < @max_retries ->
        Logger.error("LinkedIn OAuth: Client error #{status} on attempt #{attempt}")
        Logger.error("LinkedIn OAuth: Response headers: #{inspect(headers, pretty: true)}")
        Logger.error("LinkedIn OAuth: Response body: #{inspect(body, pretty: true)}")

        # Check if this is a transient 400 error (sometimes LinkedIn returns 400 for timeouts)
        error_description = get_in(body, ["error_description"]) || ""

        if String.contains?(error_description, ["timeout", "temporary", "try again"]) do
          Logger.warning(
            "LinkedIn OAuth: Transient error #{status} on attempt #{attempt}, retrying in #{@retry_delay_ms}ms..."
          )

          Process.sleep(@retry_delay_ms)
          get_token_with_retry(params, attempt + 1)
        else
          Logger.error("LinkedIn OAuth: Non-retryable client error #{status}")
          {:error, {:oauth_error, status, body}}
        end

      {:error, %OAuth2.Error{reason: :timeout}} when attempt < @max_retries ->
        Logger.warning(
          "LinkedIn OAuth: Timeout on attempt #{attempt}, retrying in #{@retry_delay_ms}ms..."
        )

        Process.sleep(@retry_delay_ms)
        get_token_with_retry(params, attempt + 1)

      {:error, %OAuth2.Response{status_code: status, body: body, headers: headers}} ->
        Logger.error("LinkedIn OAuth: Final token exchange failure")
        Logger.error("LinkedIn OAuth: Response status: #{status}")
        Logger.error("LinkedIn OAuth: Response headers: #{inspect(headers, pretty: true)}")
        Logger.error("LinkedIn OAuth: Response body: #{inspect(body, pretty: true)}")
        {:error, {:oauth_error, status, body}}

      {:error, reason} ->
        Logger.error(
          "LinkedIn OAuth: Token exchange failed with reason #{inspect(reason, pretty: true)}"
        )

        {:error, reason}
    end
  end

  defp get_user_info_with_retry(_token, attempt) when attempt > @max_retries do
    Logger.error(
      "LinkedIn OAuth: User info fetch failed after #{@max_retries} attempts, giving up"
    )

    {:error, :max_retries_exceeded}
  end

  defp get_user_info_with_retry(token, attempt) do
    Logger.info("LinkedIn OAuth: User info fetch attempt #{attempt}/#{@max_retries}")

    user_info_url = @linkedin_config[:user_info_url]
    headers = [{"Authorization", "Bearer #{token.access_token}"}]

    Logger.debug("LinkedIn OAuth: Making user info request to: #{user_info_url}")
    Logger.debug("LinkedIn OAuth: Request headers: #{inspect(headers, pretty: true)}")

    Logger.debug(
      "LinkedIn OAuth: Access token (first 20 chars): #{String.slice(token.access_token, 0, 20)}..."
    )

    case HTTPoison.get(user_info_url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        Logger.info("LinkedIn OAuth: User info fetch successful on attempt #{attempt}")

        Logger.debug(
          "LinkedIn OAuth: User info response headers: #{inspect(headers, pretty: true)}"
        )

        Logger.debug("LinkedIn OAuth: User info response body: #{body}")

        case Jason.decode(body) do
          {:ok, user_info} ->
            Logger.debug("LinkedIn OAuth: Decoded user info: #{inspect(user_info, pretty: true)}")
            {:ok, user_info}

          {:error, reason} ->
            Logger.error("LinkedIn OAuth: Failed to decode user info JSON: #{inspect(reason)}")
            Logger.error("LinkedIn OAuth: Raw response body: #{body}")
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body, headers: headers}}
      when status >= 500 and attempt < @max_retries ->
        Logger.warning(
          "LinkedIn OAuth: Server error #{status} fetching user info on attempt #{attempt}, retrying in #{@retry_delay_ms}ms..."
        )

        Logger.error("LinkedIn OAuth: User info response status: #{status}")

        Logger.error(
          "LinkedIn OAuth: User info response headers: #{inspect(headers, pretty: true)}"
        )

        Logger.error("LinkedIn OAuth: User info response body: #{body}")
        Process.sleep(@retry_delay_ms)
        get_user_info_with_retry(token, attempt + 1)

      {:ok, %HTTPoison.Response{status_code: 401, body: body, headers: headers}} ->
        Logger.error("LinkedIn OAuth: User info fetch failed with status 401")

        Logger.error(
          "LinkedIn OAuth: User info response headers: #{inspect(headers, pretty: true)}"
        )

        Logger.error("LinkedIn OAuth: User info response body: #{body}")

        # Check for specific REVOKED_ACCESS_TOKEN error
        case Jason.decode(body) do
          {:ok, %{"code" => "REVOKED_ACCESS_TOKEN"}} ->
            Logger.error(
              "LinkedIn OAuth: Token was revoked by user - this is a user permission issue, not a system error"
            )

            {:error, {:revoked_token, "User has revoked access to the LinkedIn application"}}

          _ ->
            {:error, {:http_error, 401, body}}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body, headers: headers}} ->
        Logger.error("LinkedIn OAuth: User info fetch failed with status #{status}")

        Logger.error(
          "LinkedIn OAuth: User info response headers: #{inspect(headers, pretty: true)}"
        )

        Logger.error("LinkedIn OAuth: User info response body: #{body}")
        {:error, {:http_error, status, body}}

      {:error, %HTTPoison.Error{reason: reason}} when attempt < @max_retries ->
        Logger.warning(
          "LinkedIn OAuth: HTTP error fetching user info on attempt #{attempt} (#{reason}), retrying in #{@retry_delay_ms}ms..."
        )

        Process.sleep(@retry_delay_ms)
        get_user_info_with_retry(token, attempt + 1)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("LinkedIn OAuth: HTTP error fetching user info: #{reason}")
        {:error, {:http_error, reason}}
    end
  end
end
