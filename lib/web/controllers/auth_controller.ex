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

    redirect_to_error(conn, :unknown_error, provider)
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

  def callback(conn, %{"provider" => provider_name} = params) do
    Logger.info("Processing OAuth callback for provider: #{provider_name}")
    Logger.debug("Callback params: #{inspect(params, pretty: true)}")

    case provider_config(provider_name) do
      {:ok, provider_config} ->
        Logger.debug("Provider config found for #{provider_name}")
        run_callback_with_retry(conn, provider_name, provider_config, params, 1)

      {:error, error} ->
        Logger.error("Provider config error for #{provider_name}: #{inspect(error)}")
        redirect_to_error(conn, error, provider_name)
    end
  end

  @max_oauth_retries 3
  @retry_delay_ms 1500

  defp run_callback_with_retry(conn, provider_name, provider_config, params, attempt) do
    Logger.info("OAuth attempt #{attempt}/#{@max_oauth_retries} for #{provider_name}")

    result_conn =
      conn
      |> Ueberauth.run_callback(provider_name, provider_config)

    case result_conn.assigns do
      %{ueberauth_failure: fails} when attempt < @max_oauth_retries ->
        # Check if this is a retryable error (any error containing "Error" or common failure patterns)
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
          error_messages =
            Enum.map(fails.errors, &"#{&1.message_key}: #{&1.message}") |> Enum.join(", ")

          Logger.warning(
            "OAuth error on attempt #{attempt} (#{error_messages}), retrying in #{@retry_delay_ms}ms..."
          )

          # Add delay before retry
          Process.sleep(@retry_delay_ms)
          # Retry with exponential backoff
          next_delay = @retry_delay_ms * (attempt + 1)
          run_callback_with_retry(conn, provider_name, provider_config, params, attempt + 1)
        else
          # If we can't identify the error type, try retrying anyway since user requested retry on all "Error"
          Logger.warning(
            "Unidentified OAuth error on attempt #{attempt}, retrying anyway in #{@retry_delay_ms}ms..."
          )

          Logger.error("Full error details: #{inspect(fails, pretty: true)}")
          Process.sleep(@retry_delay_ms)
          run_callback_with_retry(conn, provider_name, provider_config, params, attempt + 1)
        end

      %{ueberauth_failure: fails} ->
        error_messages =
          Enum.map(fails.errors, &"#{&1.message_key}: #{&1.message}") |> Enum.join(", ")

        Logger.error(
          "OAuth failed after #{attempt} attempts, giving up. Final errors: #{error_messages}"
        )

        callback(result_conn, params)

      _success ->
        Logger.info("OAuth succeeded on attempt #{attempt}")
        callback(result_conn, params)
    end
  end

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

  def secret_key_base do
    :mobilizon
    |> Application.get_env(Mobilizon.Web.Endpoint, [])
    |> Keyword.get(:secret_key_base)
  end
end
