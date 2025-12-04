defmodule Mobilizon.Web.AuthController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Web.OAuth.LinkedInOAuth
  alias Mobilizon.Web.Upload
  alias Mix.Tasks.Mobilizon.Actors.Utils
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]
  require Logger
  plug(:put_layout, false)

  plug(Ueberauth)

  @spec request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def request(conn, %{"provider" => "linkedin"} = params) do
    Logger.info("Starting LinkedIn OAuth request")

    # Capture intent parameter (login vs register)
    # default to register for backward compatibility
    intent = Map.get(params, "intent", "register")
    
    # Capture redirect parameter if provided
    redirect_path = Map.get(params, "redirect")

    # Generate state for CSRF protection using signed token (no session needed)
    # Include intent and redirect in the state for callback processing
    state = generate_csrf_state(intent, redirect_path)

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

          %{message_key: key, message: message} ->
            "#{key}: #{message}"

          %{message: message} ->
            "Error: #{message}"

          _ ->
            "Unknown error"
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
        params
      ) do
    email = email_from_ueberauth(auth)
    [_, _, _, strategy] = strategy |> to_string() |> String.split(".")
    strategy = String.downcase(strategy)

    Logger.info("OAuth callback received for #{strategy} with email: #{email}")

    # Validate state parameter for CSRF protection
    # Note: While Ueberauth's OAuth2 strategies should handle this internally,
    # we add explicit validation for defense in depth
    with {:ok, conn} <- validate_ueberauth_state(conn, params),
         # Determine if this is a login (existing user) or registration (new user)
         {user, is_login} <- determine_user_and_action(email, strategy, locale),
         %User{} = user <- user,
         # Update sign-in tracking information for OAuth logins
         user <- update_oauth_login_information(user, conn),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Authenticator.generate_tokens(user) do
      Logger.info("Successfully logged in user \"#{email}\" through #{strategy}")

      # Determine redirect URL based on whether this is login or registration
      redirect_url = if is_login, do: "/", else: nil

      render(conn, "callback.html", %{
        access_token: access_token,
        refresh_token: refresh_token,
        user: user,
        username: username_from_ueberauth(auth),
        name: display_name_from_ueberauth(auth),
        redirect_url: redirect_url
      })
    else
      {:error, state_error}
      when state_error in [:missing_session_state, :missing_callback_state, :state_mismatch] ->
        Logger.error("State validation failed for #{strategy}: #{state_error}")
        redirect_to_error(conn, :invalid_state, strategy)

      err ->
        Logger.error("Failed to login user \"#{email}\" - Error: #{inspect(err)}")
        redirect_to_error(conn, :unknown_error, strategy)
    end
  end

  # Extract user determination logic for clarity and reusability
  defp determine_user_and_action(email, strategy, locale) do
    {user, is_login} =
      with {:valid_email, false} <- {:valid_email, is_nil(email) or email == ""},
           {:error, :user_not_found} <- Users.get_user_by_email(email),
           {:ok, %User{} = user} <- Users.create_external(email, strategy, %{locale: locale}) do
        Logger.info("Created new external user for #{email} via #{strategy}")
        # new user = registration
        {user, false}
      else
        {:ok, %User{} = user} ->
          Logger.info("Found existing user for #{email}")
          # existing user = login
          {user, true}

        {:error, error} ->
          Logger.error("Failed to create/find user for #{email}: #{inspect(error)}")
          {{:error, error}, false}

        error ->
          Logger.error("Unexpected error during user lookup/creation: #{inspect(error)}")
          {{:error, error}, false}
      end

    {user, is_login}
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
        redirect_path = Map.get(state_data, "redirect")

        case LinkedInOAuth.authenticate(code, state) do
          {:ok, %{user_info: user_info, token: token}} ->
            Logger.info("LinkedIn OAuth: Authentication successful for #{user_info["email"]}")
            process_linkedin_user(conn, user_info, token, intent, redirect_path)

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

  defp process_linkedin_user(conn, user_info, _token, intent, redirect_path) do
    email = user_info["email"]
    name = user_info["name"] || user_info["given_name"] || email
    username = generate_username_from_linkedin(name, user_info, email)
    avatar_url = user_info["picture"]

    Logger.info("Processing LinkedIn user: #{email} with intent: #{intent}")

    Logger.debug(
      "LinkedIn profile data: name=#{name}, username=#{username}, avatar_url=#{avatar_url}"
    )

    # First, check if user exists
    case Users.get_user_by_email(email) do
      {:ok, %User{} = user} ->
        # User exists - update profile if needed and proceed with login
        Logger.info("Found existing user for #{email}")
        
        case update_user_profile_from_linkedin(user, user_info) do
          {:ok, updated_user} ->
            complete_linkedin_authentication(conn, updated_user, username, name, intent, redirect_path)
          
          {:error, error} ->
            Logger.error("Failed to update LinkedIn profile for user #{email}: #{inspect(error)}")
            redirect_to_error(conn, :profile_update_failed, "linkedin")
        end

      {:error, :user_not_found} ->
        # User doesn't exist - handle based on intent
        case intent do
          "login" ->
            # Login attempt but user doesn't exist - redirect to register
            Logger.info("Login attempt for non-existing user #{email} - redirecting to register")

            redirect(conn,
              to: "/register/user?message=no_account&provider=linkedin&email=#{URI.encode(email)}"
            )

          "register" ->
            # Registration attempt - create new user with profile
            Logger.info(
              "Registration attempt for #{email} - creating new user with LinkedIn profile"
            )

            case create_user_with_linkedin_profile(email, user_info) do
              {:ok, %User{} = user} ->
                Logger.info("Created new external user for #{email} via linkedin with profile")
                complete_linkedin_authentication(conn, user, username, name, intent, redirect_path)

              {:error, error} ->
                Logger.error("Failed to create user with profile for #{email}: #{inspect(error)}")
                redirect_to_error(conn, :user_creation_failed, "linkedin")
            end

          _ ->
            # Unknown intent - default to registration for backward compatibility
            Logger.warning("Unknown intent #{intent} for #{email} - defaulting to registration")

            case create_user_with_linkedin_profile(email, user_info) do
              {:ok, %User{} = user} ->
                Logger.info("Created new external user for #{email} via linkedin with profile")
                complete_linkedin_authentication(conn, user, username, name, "register", redirect_path)

              {:error, error} ->
                Logger.error("Failed to create user with profile for #{email}: #{inspect(error)}")
                redirect_to_error(conn, :user_creation_failed, "linkedin")
            end
        end
    end
  end

  # Helper function to complete LinkedIn authentication with tokens
  defp complete_linkedin_authentication(conn, user, username, name, intent, redirect_path) do
    # Update sign-in tracking information
    user = update_oauth_login_information(user, conn)
    
    case Authenticator.generate_tokens(user) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
        Logger.info("Successfully generated tokens for user \"#{user.email}\" through linkedin")

        # Use provided redirect path if available, otherwise determine based on intent and actor
        redirect_url =
          case redirect_path do
            nil ->
              case {intent, user.default_actor_id} do
                {"login", nil} ->
                  # Login but no actor - this should not happen after our fixes, but redirect to identity creation as fallback
                  Logger.warning("LinkedIn login for user #{user.email} with no default actor - redirecting to identity creation")
                  "/identity/create?source=linkedin"
                
                {"login", _actor_id} ->
                  # Login with actor - redirect to home
                  "/"

                {_, nil} ->
                  # Registration or other intent with no actor - redirect to create identity
                  "/identity/create?source=linkedin"

                {_, _actor_id} ->
                  # Registration or other intent with actor - redirect to edit identity
                  case Actors.get_actor(user.default_actor_id) do
                    %Actor{} = actor ->
                      "/identity/update/#{actor.preferred_username}?source=linkedin"

                    nil ->
                      # Fallback if actor lookup fails - redirect to create
                      Logger.warning("Actor #{user.default_actor_id} not found for user #{user.email} - redirecting to identity creation")
                      "/identity/create?source=linkedin"
                  end
              end
            
            path when is_binary(path) ->
              # Use the provided redirect path
              Logger.info("LinkedIn OAuth: Using provided redirect path: #{path}")
              path
          end

        # Store tokens and redirect based on intent
        render(conn, "callback_redirect.html", %{
          access_token: access_token,
          refresh_token: refresh_token,
          user: user,
          username: username,
          name: name,
          redirect_url: redirect_url
        })

      {:error, error} ->
        Logger.error("Failed to generate tokens for LinkedIn user: #{inspect(error)}")
        redirect_to_error(conn, :token_generation_failed, "linkedin")
    end
  end

  # Helper function to generate a username from LinkedIn data
  defp generate_username_from_linkedin(display_name, user_info, fallback_email) do
    # Try to generate username from display name first (like email registration), then fallbacks
    cond do
      is_valid_string(display_name) ->
        Utils.generate_username(display_name)

      is_valid_string(user_info["given_name"]) ->
        sanitize_username(user_info["given_name"])

      true ->
        fallback_email
        |> String.split("@")
        |> List.first()
        |> sanitize_username()
    end
  end

  # Sanitize username to match platform requirements
  defp sanitize_username(username) when is_binary(username) do
    username
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "")
    # Keep reasonable length
    |> String.slice(0, 20)
  end

  defp sanitize_username(_), do: "linkedin_user"

  # Create user with LinkedIn profile data
  defp create_user_with_linkedin_profile(email, user_info) do
    with {:ok, %User{} = user} <- Users.create_external(email, "linkedin", %{locale: "en"}),
         {:ok, actor} <- create_actor_from_linkedin(user, user_info),
         # Set the newly created actor as the user's default actor
         {:ok, updated_user} <-
           user |> User.changeset(%{default_actor_id: actor.id}) |> Repo.update() do
      {:ok, updated_user}
    else
      {:error, error} -> {:error, error}
    end
  end

  # Update existing user's profile with LinkedIn data if missing
  defp update_user_profile_from_linkedin(%User{} = user, user_info) do
    case user.default_actor_id do
      nil ->
        # User has no default actor, create one from LinkedIn data
        Logger.info("Creating actor profile for existing user #{user.email} from LinkedIn")

        case create_actor_from_linkedin(user, user_info) do
          {:ok, actor} ->
            # Update user's default_actor_id
            case user |> User.changeset(%{default_actor_id: actor.id}) |> Repo.update() do
              {:ok, updated_user} ->
                Logger.info("Successfully created and linked actor #{actor.id} for user #{user.email}")
                {:ok, updated_user}
              
              {:error, error} ->
                Logger.error("Failed to link actor #{actor.id} to user #{user.email}: #{inspect(error)}")
                {:error, error}
            end

          {:error, error} ->
            Logger.error("Failed to create actor for user #{user.email}: #{inspect(error)}")
            {:error, error}
        end

      _actor_id ->
        # User has an actor, optionally update missing fields
        update_actor_from_linkedin_if_needed(user, user_info)
        {:ok, user}
    end
  end

  # Update actor from LinkedIn if missing avatar or name
  defp update_actor_from_linkedin_if_needed(%User{default_actor_id: actor_id} = _user, user_info)
       when not is_nil(actor_id) do
    case Actors.get_actor(actor_id) do
      %Actor{avatar: nil} = actor ->
        Logger.info("Updating actor #{actor_id} avatar from LinkedIn")
        linkedin_avatar = download_linkedin_avatar(user_info["picture"])
        attrs = %{}
        attrs = if linkedin_avatar, do: Map.put(attrs, :avatar, linkedin_avatar), else: attrs

        case Actors.update_actor(actor, attrs) do
          {:ok, _updated_actor} ->
            Logger.info("Successfully updated actor #{actor_id} with LinkedIn data")

          {:error, error} ->
            Logger.error("Failed to update actor #{actor_id}: #{inspect(error)}")
        end

      %Actor{} ->
        # Actor already has avatar, no update needed
        :ok

      nil ->
        Logger.error("Actor #{actor_id} not found")
        :ok
    end
  end

  defp update_actor_from_linkedin_if_needed(_user, _user_info), do: :ok

  # Create actor from LinkedIn profile data
  defp create_actor_from_linkedin(%User{} = user, user_info) do
    name = user_info["name"] || user_info["given_name"] || user.email
    username = generate_username_from_linkedin(name, user_info, user.email)
    avatar = download_linkedin_avatar(user_info["picture"])

    actor_attrs = %{
      user_id: user.id,
      name: name,
      preferred_username: ensure_unique_username(username),
      summary: "LinkedIn user"
    }

    # Add avatar if successfully downloaded
    actor_attrs = if avatar, do: Map.put(actor_attrs, :avatar, avatar), else: actor_attrs

    # true = set as default actor
    case Actors.new_person(actor_attrs, true) do
      {:ok, actor} ->
        Logger.info("Created actor #{actor.id} for user #{user.email} with LinkedIn profile")
        {:ok, actor}

      {:error, error} ->
        Logger.error("Failed to create actor for user #{user.email}: #{inspect(error)}")
        {:error, error}
    end
  end

  # Download LinkedIn avatar and convert to File struct
  defp download_linkedin_avatar(nil), do: nil
  defp download_linkedin_avatar(""), do: nil

  defp download_linkedin_avatar(avatar_url) when is_binary(avatar_url) do
    Logger.info("Downloading LinkedIn avatar from: #{avatar_url}")

    case HTTPoison.get(avatar_url, [], timeout: 10_000, recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        content_type = get_content_type(headers)
        filename = "linkedin_avatar.#{get_extension_from_content_type(content_type)}"

        case Upload.store(%{body: body, name: filename}, type: :avatar) do
          {:ok, %{name: name, url: url, content_type: content_type, size: size}} ->
            %{
              name: name,
              url: url,
              content_type: content_type,
              size: size
            }

          {:error, error} ->
            Logger.error("Failed to store LinkedIn avatar: #{inspect(error)}")
            nil
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.error("Failed to download LinkedIn avatar, status: #{status}")
        nil

      {:error, error} ->
        Logger.error("Failed to download LinkedIn avatar: #{inspect(error)}")
        nil
    end
  end

  # Helper to get content type from headers
  defp get_content_type(headers) do
    headers
    |> Enum.find(fn {key, _value} -> String.downcase(key) == "content-type" end)
    |> case do
      {_key, value} -> value |> String.split(";") |> List.first() |> String.trim()
      # default fallback
      nil -> "image/jpeg"
    end
  end

  # Helper to get file extension from content type
  defp get_extension_from_content_type("image/jpeg"), do: "jpg"
  defp get_extension_from_content_type("image/jpg"), do: "jpg"
  defp get_extension_from_content_type("image/png"), do: "png"
  defp get_extension_from_content_type("image/gif"), do: "gif"
  defp get_extension_from_content_type("image/webp"), do: "webp"
  # default fallback
  defp get_extension_from_content_type(_), do: "jpg"

  # Ensure username is unique by adding numbers if needed
  defp ensure_unique_username(base_username, suffix \\ 0) do
    username = if suffix == 0, do: base_username, else: "#{base_username}#{suffix}"

    case Actors.get_local_actor_by_name(username) do
      # Username is available
      nil -> username
      # Try next number
      %Actor{} -> ensure_unique_username(base_username, suffix + 1)
    end
  end

  # CSRF state management using signed tokens (no session required)
  # Used for LinkedIn custom OAuth implementation
  defp generate_csrf_state(intent, redirect_path) do
    timestamp = System.system_time(:second)

    data = %{
      "nonce" => :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false),
      "timestamp" => timestamp,
      "intent" => intent,
      "redirect" => redirect_path
    }

    Phoenix.Token.sign(Mobilizon.Web.Endpoint, "linkedin_oauth_state", data)
  end

  defp verify_csrf_state(state) do
    case Phoenix.Token.verify(Mobilizon.Web.Endpoint, "linkedin_oauth_state", state, max_age: 600) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  # Validate OAuth state parameter for Ueberauth providers
  # Ueberauth's OAuth2 strategies should store state in session during request phase
  # and validate it during callback phase. This function provides explicit validation
  # for defense in depth.
  defp validate_ueberauth_state(conn, params) do
    session_state = get_session(conn, :ueberauth_state_param)
    callback_state = Map.get(params, "state")

    cond do
      is_nil(session_state) and is_nil(callback_state) ->
        # Some OAuth providers/strategies may not use state parameter
        # Allow this case but log a warning
        Logger.warning("OAuth callback: No state parameter used by provider")
        {:ok, conn}

      is_nil(session_state) ->
        Logger.error("OAuth callback: No state found in session - possible CSRF attack")
        {:error, :missing_session_state}

      is_nil(callback_state) ->
        Logger.error("OAuth callback: No state in callback parameters - possible CSRF attack")
        {:error, :missing_callback_state}

      session_state == callback_state ->
        Logger.debug("OAuth callback: State parameter validated successfully")
        # Clear the state from session after successful validation
        {:ok, delete_session(conn, :ueberauth_state_param)}

      true ->
        Logger.error(
          "OAuth callback: State mismatch - possible CSRF attack. " <>
            "Session: #{session_state}, Callback: #{callback_state}"
        )
        {:error, :state_mismatch}
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

  # Updates user login tracking information (current_sign_in_at, last_sign_in_at, and IP addresses)
  # for OAuth logins. This ensures OAuth users are counted in active user statistics.
  @spec update_oauth_login_information(User.t(), Plug.Conn.t()) :: User.t()
  defp update_oauth_login_information(
         %User{current_sign_in_at: current_sign_in_at, current_sign_in_ip: current_sign_in_ip} = user,
         conn
       ) do
    current_ip = get_client_ip(conn)
    now = DateTime.utc_now()

    case Users.update_user(user, %{
           last_sign_in_at: current_sign_in_at || now,
           last_sign_in_ip: current_sign_in_ip || current_ip,
           current_sign_in_ip: current_ip,
           current_sign_in_at: now
         }) do
      {:ok, updated_user} ->
        Logger.debug("Updated OAuth login information for user #{user.email}")
        updated_user

      {:error, changeset} ->
        Logger.error("Failed to update OAuth login information for user #{user.email}: #{inspect(changeset)}")
        # Return original user if update fails to not block the login flow
        user
    end
  end

  @spec get_client_ip(Plug.Conn.t()) :: String.t() | nil
  defp get_client_ip(conn) do
    # Try to get real IP from forwarded headers first (for proxied requests)
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        # Take the first IP in the chain (original client)
        ip
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        # Fall back to remote_ip from conn
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          {a, b, c, d, e, f, g, h} -> "#{a}:#{b}:#{c}:#{d}:#{e}:#{f}:#{g}:#{h}"
          _ -> nil
        end
    end
  end

  def secret_key_base do
    :mobilizon
    |> Application.get_env(Mobilizon.Web.Endpoint, [])
    |> Keyword.get(:secret_key_base)
  end
end
