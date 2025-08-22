defmodule Mobilizon.Web.AuthController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]
  require Logger
  plug(:put_layout, false)

  plug(Plug.Session,
    store: :cookie,
    key: "_auth_callback",
    signing_salt: {Mobilizon.Web.AuthController, :secret_key_base, []}
  )

  plug(Ueberauth)

  @spec request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def request(conn, %{"provider" => provider_name} = _params) do
    case provider_config(provider_name) do
      {:ok, provider_config} ->
        conn
        |> Ueberauth.run_request(provider_name, provider_config)

      {:error, error} ->
        redirect_to_error(conn, error, provider_name)
    end
  end

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, any()}
  def callback(
        %{assigns: %{ueberauth_failure: fails}} = conn,
        %{"provider" => provider} = _params
      ) do
    Logger.error("=== OAUTH FAILURE CALLBACK TRIGGERED ===")
    Logger.error("Provider: #{provider}")
    Logger.error("Environment: #{Mix.env()}")
    Logger.error("OAuth callback failure for #{provider}: #{inspect(fails, pretty: true)}")

    # Log specific failure reasons for debugging
    failure_reasons =
      fails.errors
      |> Enum.map(fn error ->
        case error do
          %{message_key: "OAuth2", message: message} ->
            # Try to extract more details from OAuth2 errors
            Logger.error("OAuth2 detailed error: #{inspect(error, pretty: true)}")
            "OAuth2: #{message}"

          _ ->
            "#{error.message_key}: #{error.message}"
        end
      end)
      |> Enum.join(", ")

    Logger.error("OAuth failure reasons: #{failure_reasons}")

    # Log additional debugging information
    Logger.error("Request params: #{inspect(conn.params, pretty: true)}")
    Logger.error("Query string: #{conn.query_string}")

    # Check if this is a retryable error and show retry screen
    has_retryable_error =
      Enum.any?(fails.errors, fn error ->
        String.contains?(error.message, "Error") or
          String.contains?(error.message, "error") or
          String.contains?(error.message, "timeout") or
          String.contains?(error.message, "failed") or
          String.contains?(error.message, "Unknown") or
          error.message_key == "OAuth2"
      end)

    if has_retryable_error do
      Logger.info("OAuth failure is retryable, showing retry screen for #{provider}")
      show_retry_screen(conn, provider, 1, failure_reasons)
    else
      Logger.error("OAuth failure is not retryable, redirecting to error for #{provider}")
      redirect_to_error(conn, :unknown_error, provider)
    end
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Ueberauth.Auth{strategy: strategy} = auth, locale: locale}} =
          conn,
        _params
      ) do
    email = email_from_ueberauth(auth)
    [_, _, _, strategy] = strategy |> to_string() |> String.split(".")
    strategy = String.downcase(strategy)

    Logger.info("OAuth callback received for #{strategy} with email: #{email}")
    Logger.debug("OAuth auth data: #{inspect(auth, pretty: true)}")

    user =
      with {:valid_email, false} <- {:valid_email, is_nil(email) or email == ""},
           {:error, :user_not_found} <- Users.get_user_by_email(email),
           {:ok, %User{} = user} <- Users.create_external(email, strategy, %{locale: locale}) do
        Logger.info("Created new external user for #{email} via #{strategy}")
        user
      else
        {:ok, %User{} = user} ->
          Logger.info("Found existing user for #{email}")
          user

        {:error, error} ->
          Logger.error("Failed to create/find user for #{email}: #{inspect(error)}")
          {:error, error}

        error ->
          Logger.error("Unexpected error during user lookup/creation: #{inspect(error)}")
          {:error, error}
      end

    with %User{} = user <- user,
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Authenticator.generate_tokens(user) do
      Logger.info("Successfully generated tokens for user \"#{email}\" through #{strategy}")

      render(conn, "callback.html", %{
        access_token: access_token,
        refresh_token: refresh_token,
        user: user,
        username: username_from_ueberauth(auth),
        name: display_name_from_ueberauth(auth)
      })
    else
      err ->
        Logger.error("Failed to login user \"#{email}\" - Error: #{inspect(err, pretty: true)}")
        redirect_to_error(conn, :unknown_error, strategy)
    end
  end

  # This should only be called for unhandled cases (fallback)
  def callback(conn, params) do
    Logger.warning("=== FALLBACK CALLBACK TRIGGERED ===")
    Logger.warning("Environment: #{Mix.env()}")
    Logger.warning("Request URL: #{conn.request_path}?#{conn.query_string}")
    Logger.warning("Unhandled OAuth callback: #{inspect(params, pretty: true)}")
    Logger.warning("Connection assigns: #{inspect(conn.assigns, pretty: true)}")

    case params do
      %{"provider" => provider_name} ->
        # Check if this might be an OAuth failure that wasn't caught by Ueberauth
        # Look for error indicators in the URL params
        has_oauth_error =
          params["error"] ||
            params["error_description"] ||
            (params["code"] && is_binary(params["code"]) &&
               String.contains?(params["code"], "Error"))

        if has_oauth_error do
          Logger.warning(
            "Detected OAuth error in fallback callback for #{provider_name}, showing retry screen"
          )

          Logger.warning("Error details: #{inspect(params, pretty: true)}")

          # Simulate a failure and show retry screen
          error_message =
            params["error_description"] || params["error"] || params["code"] ||
              "OAuth callback failed"

          show_retry_screen(conn, provider_name, 1, error_message)
        else
          Logger.error("OAuth callback was not handled by specific handlers for #{provider_name}")
          redirect_to_error(conn, :unknown_error, provider_name)
        end

      _ ->
        Logger.error("OAuth callback missing provider parameter")
        redirect(conn, to: "/login?code=Error with Login Provider")
    end
  end

  @max_oauth_retries 20
  @retry_delay_ms 1500

  # Github only give public emails as part of the user profile,
  # so we explicitely request all user emails and filter on the primary one
  @spec email_from_ueberauth(Ueberauth.Auth.t()) :: String.t() | nil
  defp email_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.Github,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"emails" => emails}}}
       })
       when length(emails) > 0,
       do: emails |> Enum.find(& &1["primary"]) |> (& &1["email"]).()

  defp email_from_ueberauth(%Ueberauth.Auth{
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"email" => email}}}
       })
       when is_valid_string(email),
       do: email

  defp email_from_ueberauth(%Ueberauth.Auth{info: %Ueberauth.Auth.Info{email: email}})
       when is_valid_string(email),
       do: email

  defp email_from_ueberauth(_), do: nil

  defp username_from_ueberauth(%Ueberauth.Auth{info: %Ueberauth.Auth.Info{nickname: nickname}})
       when is_valid_string(nickname),
       do: nickname

  defp username_from_ueberauth(_), do: nil

  defp display_name_from_ueberauth(%Ueberauth.Auth{info: %Ueberauth.Auth.Info{name: name}})
       when is_valid_string(name),
       do: name

  defp display_name_from_ueberauth(_), do: nil

  @spec provider_config(String.t()) :: {:ok, any()} | {:error, :not_supported | :unknown_error}
  defp provider_config(provider_name) do
    with ueberauth when is_list(ueberauth) <- Application.get_env(:ueberauth, Ueberauth),
         providers when is_list(providers) <- Keyword.get(ueberauth, :providers),
         providers_keys <- providers |> Keyword.keys() |> Enum.map(&Atom.to_string/1),
         {:supported, true} <- {:supported, provider_name in providers_keys},
         provider_name <- String.to_existing_atom(provider_name),
         provider_config <- Keyword.get(providers, provider_name) do
      {:ok, provider_config}
    else
      {:supported, false} ->
        {:error, :not_supported}

      _ ->
        {:error, :unknown_error}
    end
  end

  @spec redirect_to_error(Plug.Conn.t(), atom(), String.t()) :: Plug.Conn.t()
  defp redirect_to_error(conn, :not_supported, provider_name) do
    redirect(conn, to: "/login?code=Login Provider not found&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :unknown_error, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :invalid_token, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  # Show retry loading screen with countdown
  defp show_retry_screen(conn, provider_name, attempt, error_message) do
    retry_delay_seconds = div(@retry_delay_ms, 1000)

    # Generate signed retry URL to prevent direct access
    retry_token =
      Phoenix.Token.sign(Mobilizon.Web.Endpoint, "oauth_retry", %{
        "provider" => provider_name,
        "attempt" => attempt + 1,
        "timestamp" => System.system_time(:second)
      })

    retry_url = "/auth/retry/#{provider_name}?token=#{retry_token}"

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(
      200,
      render_retry_html(provider_name, attempt, retry_delay_seconds, error_message, retry_url)
    )
  end

  # Handle retry requests from the loading screen
  def retry_oauth(conn, %{"provider" => provider_name, "token" => token}) do
    Logger.info("=== RETRY OAUTH REQUEST ===")
    Logger.info("Environment: #{Mix.env()}")
    Logger.info("Provider: #{provider_name}")
    Logger.info("Token received: #{String.slice(token, 0, 20)}...")

    case Phoenix.Token.verify(Mobilizon.Web.Endpoint, "oauth_retry", token, max_age: 300) do
      {:ok, %{"provider" => ^provider_name, "attempt" => attempt}} ->
        Logger.info(
          "Processing OAuth retry #{attempt} for #{provider_name} - starting fresh OAuth flow"
        )

        if attempt <= @max_oauth_retries do
          # Start a completely fresh OAuth request instead of re-processing failed callback
          Logger.info(
            "Redirecting to fresh OAuth request for #{provider_name} (attempt #{attempt}/#{@max_oauth_retries})"
          )

          Logger.info("Redirect URL: /auth/#{provider_name}")
          redirect(conn, to: "/auth/#{provider_name}")
        else
          Logger.error("Max retry attempts (#{@max_oauth_retries}) exceeded for #{provider_name}")
          redirect_to_error(conn, :unknown_error, provider_name)
        end

      {:error, reason} ->
        Logger.error("Invalid retry token for #{provider_name}: #{inspect(reason)}")
        redirect_to_error(conn, :invalid_token, provider_name)
    end
  end

  # Render retry HTML directly to avoid template issues
  defp render_retry_html(provider_name, _attempt, retry_delay_seconds, _error_message, retry_url) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Authenticating...</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background-color: #f9fafb; min-height: 100vh;
                display: flex; align-items: center; justify-content: center; padding: 16px;
            }
            .container { width: 100%; max-width: 448px; }
            .card {
                background: white; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
                border: 1px solid #e5e7eb; padding: 48px 24px; text-align: center;
            }
            .icon-container { margin-bottom: 24px; }
            .icon {
                width: 48px; height: 48px; margin: 0 auto; background-color: #2563eb;
                border-radius: 8px; display: flex; align-items: center; justify-content: center;
            }
            .icon svg { width: 24px; height: 24px; fill: white; }
            .title {
                font-size: 24px; font-weight: bold; color: #111827; margin-bottom: 24px;
            }
            .message-box {
                background-color: #fef3c7; border: 1px solid #fbbf24;
                color: #92400e; padding: 12px 16px; font-size: 14px; margin-bottom: 24px;
                display: flex; align-items: center; justify-content: center;
            }
            .spinner {
                width: 16px; height: 16px; border: 2px solid #92400e;
                border-top: 2px solid transparent; border-radius: 50%;
                animation: spin 1s linear infinite; margin-right: 8px;
            }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
            .progress-container {
                width: 100%; height: 8px; background-color: #e5e7eb;
                border-radius: 4px; margin-bottom: 24px; overflow: hidden;
            }
            .progress-bar {
                height: 100%; background-color: #2563eb; border-radius: 4px;
                transition: width 0.3s ease; width: 0%;
            }
            .cancel-button {
                font-size: 14px; background-color: #4b5563; color: white;
                padding: 4px 12px; text-decoration: none; display: inline-block;
                transition: background-color 0.2s; border-radius: 4px;
            }
            .cancel-button:hover { background-color: #374151; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="card">
                <!-- LinkedIn icon -->
                <div class="icon-container">
                    <div class="icon">
                        <svg viewBox="0 0 24 24">
                            <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                        </svg>
                    </div>
                </div>

                <!-- Title -->
                <h1 class="title">Authenticating with #{String.capitalize(provider_name)}</h1>

                <!-- Loading message with spinner -->
                <div class="message-box">
                    <div class="spinner"></div>
                    <span>Connecting to #{String.capitalize(provider_name)}...</span>
                </div>

                <!-- Progress indicator -->
                <div class="progress-container">
                    <div class="progress-bar" id="progress"></div>
                </div>

                <!-- Cancel button -->
                <a href="/login" class="cancel-button">Cancel and return to login</a>
            </div>
        </div>

        <script>
            let countdown = #{retry_delay_seconds};
            let totalTime = #{retry_delay_seconds};
            const progressEl = document.getElementById('progress');

            const timer = setInterval(() => {
                countdown--;
                const progress = ((totalTime - countdown) / totalTime) * 100;
                progressEl.style.width = progress + '%';

                if (countdown <= 0) {
                    clearInterval(timer);
                    progressEl.style.width = '100%';
                    setTimeout(() => { window.location.href = '#{retry_url}'; }, 500);
                }
            }, 1000);

            document.addEventListener('visibilitychange', () => {
                if (document.hidden) clearInterval(timer);
            });
        </script>
    </body>
    </html>
    """
  end

  def secret_key_base do
    :mobilizon
    |> Application.get_env(Mobilizon.Web.Endpoint, [])
    |> Keyword.get(:secret_key_base)
  end
end
