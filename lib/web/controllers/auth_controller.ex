defmodule Mobilizon.Web.AuthController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Web.OAuth.LinkedInOAuth
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]
  require Logger
  plug(:put_layout, false)

  plug(Ueberauth)

  @spec request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def request(conn, %{"provider" => "linkedin"} = params) do
    Logger.info("Starting LinkedIn OAuth request")

    # Capture intent parameter (login vs register)
    intent = Map.get(params, "intent", "register")  # default to register for backward compatibility

    # Generate state for CSRF protection using signed token (no session needed)
    # Include intent in the state for callback processing
    state = generate_csrf_state(intent)

    # Get authorization URL from our custom LinkedIn implementation
    case LinkedInOAuth.authorize_url(state) do
      url when is_binary(url) ->
        redirect(conn, external: url)

      {:error, reason} ->
        Logger.error("Failed to generate LinkedIn OAuth URL: #{inspect(reason)}")
        redirect_to_error(conn, :unknown_error, "linkedin")
    end
  end

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
    Logger.error("OAuth failure callback for #{provider}")

    # Extract failure reasons
    failure_reasons =
      fails.errors
      |> Enum.map(fn error ->
        case error do
          %{message_key: "OAuth2", message: message} ->
            "OAuth2: #{message}"
          _ ->
            "#{error.message_key}: #{error.message}"
        end
      end)
      |> Enum.join(", ")

    Logger.error("OAuth failure reasons: #{failure_reasons}")

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
      Logger.info("Showing retry screen for #{provider}")
      show_retry_screen(conn, provider, 1, failure_reasons)
    else
      Logger.error("Non-retryable OAuth failure for #{provider}")
      redirect_to_error(conn, :unknown_error, provider)
    end
  end

  def callback(conn, %{"provider" => "linkedin"} = params) do
    Logger.info("Processing LinkedIn OAuth callback")

    case params do
      %{"code" => code, "state" => state} ->
        handle_linkedin_callback(conn, code, state)

      %{"error" => error, "error_description" => description} ->
        Logger.error("LinkedIn OAuth error: #{error} - #{description}")
        redirect_to_error(conn, :oauth_error, "linkedin")

      _ ->
        Logger.error("LinkedIn OAuth callback missing required parameters")
        redirect_to_error(conn, :invalid_callback, "linkedin")
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
      Logger.info("Successfully logged in user \"#{email}\" through #{strategy}")

      render(conn, "callback.html", %{
        access_token: access_token,
        refresh_token: refresh_token,
        user: user,
        username: username_from_ueberauth(auth),
        name: display_name_from_ueberauth(auth)
      })
    else
      err ->
        Logger.error("Failed to login user \"#{email}\" - Error: #{inspect(err)}")
        redirect_to_error(conn, :unknown_error, strategy)
    end
  end

  # This should only be called for unhandled cases (fallback)
  def callback(conn, params) do
    Logger.warning("Fallback OAuth callback triggered for: #{conn.request_path}")

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
          Logger.warning("OAuth error detected for #{provider_name}, showing retry screen")

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

  # Custom LinkedIn OAuth handler
  defp handle_linkedin_callback(conn, code, state) do
    Logger.info("LinkedIn OAuth: Processing callback")

    # Verify state for CSRF protection using signed token
    case verify_csrf_state(state) do
      {:ok, state_data} ->
        Logger.info("LinkedIn OAuth: State verified")
        intent = Map.get(state_data, "intent", "register")

        case LinkedInOAuth.authenticate(code, state) do
          {:ok, %{user_info: user_info, token: token}} ->
            Logger.info("LinkedIn OAuth: Authentication successful for #{user_info["email"]}")
            process_linkedin_user(conn, user_info, token, intent)

          {:error, {:revoked_token, message}} ->
            Logger.error("LinkedIn OAuth: User revoked token - #{message}")

            # Show a specific error message for revoked tokens
            conn
            |> put_flash(
              :error,
              "LinkedIn access was revoked. Please try again and grant permissions to your LinkedIn account."
            )
            |> redirect(to: "/login?code=LinkedIn Access Revoked&provider=linkedin")

          {:error, reason} ->
            Logger.error("LinkedIn OAuth: Authentication failed - #{inspect(reason)}")
            redirect_to_error(conn, :authentication_failed, "linkedin")
        end

      {:error, _reason} ->
        Logger.error("LinkedIn OAuth: State verification failed")
        redirect_to_error(conn, :invalid_state, "linkedin")
    end
  end

  defp process_linkedin_user(conn, user_info, _token, intent \\ "register") do
    email = user_info["email"]
    name = user_info["name"] || user_info["given_name"] || email
    username = user_info["sub"] || email

    Logger.info("Processing LinkedIn user: #{email} with intent: #{intent}")

    # First, check if user exists
    case Users.get_user_by_email(email) do
      {:ok, %User{} = user} ->
        # User exists - proceed with login regardless of intent
        Logger.info("Found existing user for #{email}")
        complete_linkedin_authentication(conn, user, username, name)

      {:error, :user_not_found} ->
        # User doesn't exist - handle based on intent
        case intent do
          "login" ->
            # Login attempt but user doesn't exist - redirect to register
            Logger.info("Login attempt for non-existing user #{email} - redirecting to register")
            redirect(conn, to: "/register/user?message=no_account&provider=linkedin&email=#{URI.encode(email)}")

          "register" ->
            # Registration attempt - create new user
            Logger.info("Registration attempt for #{email} - creating new user")
            case Users.create_external(email, "linkedin", %{locale: "en"}) do
              {:ok, %User{} = user} ->
                Logger.info("Created new external user for #{email} via linkedin")
                complete_linkedin_authentication(conn, user, username, name)

              {:error, error} ->
                Logger.error("Failed to create user for #{email}: #{inspect(error)}")
                redirect_to_error(conn, :user_creation_failed, "linkedin")
            end

          _ ->
            # Unknown intent - default to registration for backward compatibility
            Logger.warn("Unknown intent #{intent} for #{email} - defaulting to registration")
            case Users.create_external(email, "linkedin", %{locale: "en"}) do
              {:ok, %User{} = user} ->
                Logger.info("Created new external user for #{email} via linkedin")
                complete_linkedin_authentication(conn, user, username, name)

              {:error, error} ->
                Logger.error("Failed to create user for #{email}: #{inspect(error)}")
                redirect_to_error(conn, :user_creation_failed, "linkedin")
            end
        end
    end
  end

  # Helper function to complete LinkedIn authentication with tokens
  defp complete_linkedin_authentication(conn, user, username, name) do
    case Authenticator.generate_tokens(user) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
        Logger.info("Successfully generated tokens for user \"#{user.email}\" through linkedin")

        render(conn, "callback.html", %{
          access_token: access_token,
          refresh_token: refresh_token,
          user: user,
          username: username,
          name: name
        })

      {:error, error} ->
        Logger.error("Failed to generate tokens for LinkedIn user: #{inspect(error)}")
        redirect_to_error(conn, :token_generation_failed, "linkedin")
    end
  end

  # CSRF state management using signed tokens (no session required)
  defp generate_csrf_state(intent \\ "register") do
    timestamp = System.system_time(:second)

    data = %{
      "nonce" => :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false),
      "timestamp" => timestamp,
      "intent" => intent
    }

    Phoenix.Token.sign(Mobilizon.Web.Endpoint, "linkedin_oauth_state", data)
  end

  defp verify_csrf_state(state) do
    case Phoenix.Token.verify(Mobilizon.Web.Endpoint, "linkedin_oauth_state", state, max_age: 600) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  # Extract email from OIDC or traditional OAuth responses
  @spec email_from_ueberauth(Ueberauth.Auth.t()) :: String.t() | nil

  # LinkedIn OIDC: email comes in the ID token user data
  defp email_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.LinkedIn,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"email" => email}}}
       })
       when is_valid_string(email),
       do: email

  # Github only give public emails as part of the user profile,
  # so we explicitely request all user emails and filter on the primary one
  defp email_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.Github,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"emails" => emails}}}
       })
       when length(emails) > 0,
       do: emails |> Enum.find(& &1["primary"]) |> (& &1["email"]).()

  # Generic fallback for other providers or OIDC info field
  defp email_from_ueberauth(%Ueberauth.Auth{
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"email" => email}}}
       })
       when is_valid_string(email),
       do: email

  defp email_from_ueberauth(%Ueberauth.Auth{info: %Ueberauth.Auth.Info{email: email}})
       when is_valid_string(email),
       do: email

  defp email_from_ueberauth(_), do: nil

  # Extract username - for LinkedIn OIDC this might be the 'sub' field
  defp username_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.LinkedIn,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"sub" => sub}}}
       })
       when is_valid_string(sub),
       do: sub

  defp username_from_ueberauth(%Ueberauth.Auth{info: %Ueberauth.Auth.Info{nickname: nickname}})
       when is_valid_string(nickname),
       do: nickname

  defp username_from_ueberauth(_), do: nil

  # Extract display name - OIDC provides 'name', 'given_name', 'family_name'
  defp display_name_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.LinkedIn,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"name" => name}}}
       })
       when is_valid_string(name),
       do: name

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

  defp redirect_to_error(conn, :oauth_error, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :invalid_callback, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :authentication_failed, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :invalid_state, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :token_generation_failed, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  defp redirect_to_error(conn, :processing_failed, provider_name) do
    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider_name}")
  end

  # Redirect to Vue component for retry handling
  defp show_retry_screen(conn, provider_name, attempt, error_message) do
    retry_delay_seconds = div(@retry_delay_ms, 1000)

    # Generate signed retry token to prevent direct access
    retry_token =
      Phoenix.Token.sign(Mobilizon.Web.Endpoint, "oauth_retry", %{
        "provider" => provider_name,
        "attempt" => attempt + 1,
        "timestamp" => System.system_time(:second)
      })

    Logger.info(
      "Redirecting to Vue LinkedIn retry handler for #{provider_name}, attempt #{attempt}"
    )

    # Redirect to Vue route that will handle the retry with all necessary parameters
    vue_retry_url =
      "/auth/retry?provider=#{provider_name}&attempt=#{attempt}&delay=#{retry_delay_seconds}&token=#{retry_token}&error=#{URI.encode(error_message)}"

    Logger.info("Vue retry URL: #{vue_retry_url}")
    redirect(conn, to: vue_retry_url)
  end

  # Handle retry requests from the loading screen
  def retry_oauth(conn, %{"provider" => provider_name, "token" => token}) do
    Logger.info("=== RETRY OAUTH REQUEST ===")
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

  def secret_key_base do
    :mobilizon
    |> Application.get_env(Mobilizon.Web.Endpoint, [])
    |> Keyword.get(:secret_key_base)
  end
end
