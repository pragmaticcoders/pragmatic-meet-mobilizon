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
    Logger.warning("Unhandled OAuth callback: #{inspect(params, pretty: true)}")
    Logger.warning("Connection assigns: #{inspect(conn.assigns, pretty: true)}")

    case params do
      %{"provider" => provider_name} ->
        Logger.error("OAuth callback was not handled by specific handlers for #{provider_name}")
        redirect_to_error(conn, :unknown_error, provider_name)

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
    case Phoenix.Token.verify(Mobilizon.Web.Endpoint, "oauth_retry", token, max_age: 300) do
      {:ok, %{"provider" => ^provider_name, "attempt" => attempt}} ->
        Logger.info(
          "Processing OAuth retry #{attempt} for #{provider_name} - starting fresh OAuth flow"
        )

        if attempt <= @max_oauth_retries do
          # Start a completely fresh OAuth request instead of re-processing failed callback
          Logger.info("Redirecting to fresh OAuth request for #{provider_name}")
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
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
            .spinner { animation: spin 1s linear infinite; }
        </style>
    </head>
    <body class="bg-gray-50 min-h-screen flex items-center justify-center px-4">
        <div class="w-full max-w-md">
            <!-- Loading card with LoginView.vue styling -->
            <div class="bg-white shadow-sm border border-gray-200 px-6 py-8 text-center">
                <!-- LinkedIn icon -->
                <div class="mb-6">
                    <div class="w-12 h-12 mx-auto bg-blue-600 rounded-lg flex items-center justify-center">
                        <svg class="w-6 h-6 text-white" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                        </svg>
                    </div>
                </div>

                <!-- Title -->
                <h1 class="text-2xl font-bold text-gray-900 mb-6">
                    Authenticating with #{String.capitalize(provider_name)}
                </h1>

                <!-- Loading message with spinner (matches LoginView.vue) -->
                <div class="bg-orange-50 border border-orange-200 text-orange-800 px-4 py-3 text-sm mb-6">
                    <div class="flex items-center justify-center">
                        <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-orange-800 mr-2 spinner"></div>
                        <span>Connecting to #{String.capitalize(provider_name)}...</span>
                    </div>
                </div>

                <!-- Progress indicator -->
                <div class="w-full bg-gray-200 rounded-full h-2 mb-6">
                    <div class="bg-blue-600 h-2 rounded-full progress-bar" id="progress" style="width: 0%"></div>
                </div>

                <!-- Cancel button (matches LoginView.vue button styling) -->
                <a href="/login" class="text-sm bg-gray-600 hover:bg-gray-700 text-white px-3 py-1 transition-colors duration-200 inline-block">
                    Cancel and return to login
                </a>
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

            // Clean up timer if page becomes hidden
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
