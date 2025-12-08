defmodule Mobilizon.GraphQL.Resolvers.User do
  @moduledoc """
  Handles the user-related GraphQL calls.
  """

  import Mobilizon.Users.Guards

  alias Mobilizon.{Actors, Admin, Config, Events, FollowedGroupActivity, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Service.AntiSpam
  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.{Setting, User}

  alias Mobilizon.Web.{Auth, Email}
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Find an user by its ID
  """
  @spec find_user(any(), map(), Absinthe.Resolution.t()) :: {:ok, User.t()} | {:error, String.t()}
  def find_user(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}})
      when is_moderator(role) do
    case Users.get_user_with_actors(id) do
      {:ok, %User{} = user} ->
        {:ok, user}

      _ ->
        {:error, :user_not_found}
    end
  end

  def find_user(_parent, _args, _resolution) do
    {:error, :unauthorized}
  end

  @doc """
  Return current logged-in user
  """
  @spec get_current_user(any, map(), Absinthe.Resolution.t()) ::
          {:error, :unauthenticated} | {:ok, Mobilizon.Users.User.t()}
  def get_current_user(_parent, _args, %{context: %{current_user: %User{} = user}}) do
    Logger.debug("Resolving current user", %{
      user_id: user.id,
      user_email: user.email,
      default_actor_id: user.default_actor_id,
      default_actor_loaded: user.default_actor != %Ecto.Association.NotLoaded{}
    })
    {:ok, user}
  end

  def get_current_user(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @doc """
  List instance users
  """
  @spec list_users(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(User.t())} | {:error, :unauthorized}
  def list_users(
        _parent,
        args,
        %{context: %{current_user: %User{role: role}}}
      )
      when is_moderator(role) do
    {:ok, Users.list_users(Keyword.new(args))}
  end

  def list_users(_parent, _args, _resolution) do
    {:error, :unauthorized}
  end

  @doc """
  Login an user. Returns a token and the user
  """
  @spec login_user(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, :user_not_found | String.t()}
  def login_user(_parent, %{email: email, password: password}, %{context: context}) do
    with {:ok,
          %{
            access_token: _access_token,
            refresh_token: _refresh_token,
            user: %User{} = user
          } = user_and_tokens} <- Authenticator.authenticate(email, password),
         {:ok, %User{} = user} <- update_user_login_information(user, context),
         {:ok, %User{} = user} <- ensure_user_has_default_actor(user) do
      {:ok, %{user_and_tokens | user: user}}
    else
      {:error, :user_not_found} ->
        {:error, :user_not_found}

      {:error, :disabled_user} ->
        {:error, dgettext("errors", "This user has been disabled")}

      {:error, _error} ->
        {:error,
         dgettext(
           "errors",
           "Impossible to authenticate, either your email or password are invalid."
         )}
    end
  end

  @doc """
  Refresh a token
  """
  @spec refresh_token(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def refresh_token(_parent, %{refresh_token: refresh_token}, _resolution) do
    with {:ok, user, _claims} <- Auth.Guardian.resource_from_token(refresh_token),
         {:ok, _old, {exchanged_token, _claims}} <-
           Auth.Guardian.exchange(refresh_token, "refresh", "access"),
         {:ok, new_refresh_token} <- Authenticator.generate_refresh_token(user),
         {:ok, _claims} <- Auth.Guardian.revoke(refresh_token) do
      {:ok, %{access_token: exchanged_token, refresh_token: new_refresh_token}}
    else
      {:error, message} ->
        Logger.debug("Cannot refresh user token: #{inspect(message)}")
        {:error, dgettext("errors", "Cannot refresh the token")}
    end
  end

  def refresh_token(_parent, _params, _context) do
    {:error, dgettext("errors", "You need to have an existing token to get a refresh token")}
  end

  @spec logout(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, String.t()}
          | {:error, :token_not_found | :unable_to_logout | :unauthenticated | :invalid_argument}
  def logout(_parent, %{refresh_token: refresh_token}, %{context: %{current_user: %User{}}}) do
    with {:ok, _claims} <- Auth.Guardian.decode_and_verify(refresh_token, %{"typ" => "refresh"}),
         {:ok, _claims} <- Auth.Guardian.revoke(refresh_token) do
      {:ok, refresh_token}
    else
      {:error, :token_not_found} ->
        {:error, :token_not_found}

      {:error, error} ->
        Logger.debug("Cannot remove user refresh token: #{inspect(error)}")
        {:error, :unable_to_logout}
    end
  end

  def logout(_parent, %{refresh_token: _refresh_token}, _context) do
    {:error, :unauthenticated}
  end

  def logout(_parent, _params, _context) do
    {:error, :invalid_argument}
  end

  @doc """
  Register an user:
    - check registrations are enabled
    - create the user
    - send a validation email to the user
  """
  @spec create_user(any, %{email: String.t()}, any) :: {:ok, User.t()} | {:error, String.t()}
  def create_user(_parent, %{email: email} = args, %{context: context}) do
    current_ip = Map.get(context, :ip)
    user_agent = Map.get(context, :user_agent, "")
    now = DateTime.utc_now()

    with {:ok, email} <- lowercase_domain(email),
         :registration_ok <- check_registration_config(email),
         :not_deny_listed <- check_registration_denylist(email),
         {:spam, :ham} <-
           {:spam, AntiSpam.service().check_user(email, current_ip, user_agent)},
         {:ok, %User{} = user} <-
           args
           |> Map.merge(%{email: email, current_sign_in_ip: current_ip, current_sign_in_at: now})
           |> Users.register() do
      Email.User.send_confirmation_email(user, Map.get(args, :locale, "en"))
      {:ok, user}
    else
      {:error, :invalid_email} ->
        {:error, dgettext("errors", "Your email seems to be using an invalid format")}

      :registration_closed ->
        {:error, dgettext("errors", "Registrations are not open")}

      :not_allowlisted ->
        {:error, dgettext("errors", "Your email is not on the allowlist")}

      :deny_listed ->
        {:error,
         dgettext(
           "errors",
           "Your e-mail has been denied registration or uses a disallowed e-mail provider"
         )}

      {:spam, _} ->
        {:error,
         dgettext(
           "errors",
           "Your registration has been detected as spam and cannot be processed."
         )}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec check_registration_config(String.t()) ::
          :registration_ok | :registration_closed | :not_allowlisted
  defp check_registration_config(email) do
    cond do
      Config.instance_registrations_open?() ->
        :registration_ok

      Config.instance_registrations_allowlist?() ->
        check_allow_listed_email(email)

      true ->
        :registration_closed
    end
  end

  @spec check_registration_denylist(String.t()) :: :deny_listed | :not_deny_listed
  defp check_registration_denylist(email) do
    # Remove everything behind the +
    email = String.replace(email, ~r/(\+.*)(?=\@)/, "")

    if email_in_list?(email, Config.instance_registrations_denylist()),
      do: :deny_listed,
      else: :not_deny_listed
  end

  @spec check_allow_listed_email(String.t()) :: :registration_ok | :not_allowlisted
  defp check_allow_listed_email(email) do
    if email_in_list?(email, Config.instance_registrations_allowlist()),
      do: :registration_ok,
      else: :not_allowlisted
  end

  @spec email_in_list?(String.t(), list(String.t())) :: boolean()
  defp email_in_list?(email, list) do
    [_, domain] = split_email(email)

    domain in list or email in list
  end

  # Domains should always be lower-case, so let's force that
  @spec lowercase_domain(String.t()) :: {:ok, String.t()} | {:error, :invalid_email}
  defp lowercase_domain(email) when is_binary(email) do
    case split_email(email) do
      [user_part, domain_part] ->
        {:ok, "#{user_part}@#{String.downcase(domain_part)}"}

      _ ->
        {:error, :invalid_email}
    end
  end

  defp lowercase_domain(_), do: {:error, :invalid_email}

  @spec split_email(String.t()) :: list(String.t())
  defp split_email(email), do: String.split(email, "@", parts: 2, trim: true)

  @doc """
  Validate an user, get its actor and a token
  """
  @spec validate_user(map(), %{token: String.t()}, map()) :: {:ok, map()} | {:error, String.t()}
  def validate_user(_parent, %{token: token}, _resolution) do
    with {:ok, %User{} = user} <- Email.User.check_confirmation_token(token),
         {:ok, %User{} = user} <- ensure_user_has_default_actor(user) do
      actor = Users.get_actor_for_user(user)

      {:ok, %{access_token: access_token, refresh_token: refresh_token}} =
        Authenticator.generate_tokens(user)

      {:ok,
       %{
         access_token: access_token,
         refresh_token: refresh_token,
         user: Map.put(user, :default_actor, actor)
       }}
    else
      {:error, :invalid_token} ->
        Logger.info("Invalid token #{token} to validate user")
        {:error, dgettext("errors", "Unable to validate user")}

      {:error, %Ecto.Changeset{} = err} ->
        Logger.info("Unable to validate user with token #{token}")
        Logger.debug(inspect(err))
        {:error, dgettext("errors", "Unable to validate user")}

      {:error, error} ->
        Logger.error("Failed to ensure user has default actor during validation: #{inspect(error)}")
        {:error, dgettext("errors", "Unable to validate user")}
    end
  end

  @doc """
  Send the confirmation email again.
  We only do this to accounts not activated
  """
  def resend_confirmation_email(_parent, args, _resolution) do
    with {:ok, email} <- lowercase_domain(Map.get(args, :email)),
         {:ok, %User{locale: locale} = user} <-
           Users.get_user_by_email(email, activated: false, unconfirmed: false),
         {:ok, email} <-
           Email.User.resend_confirmation_email(user, Map.get(args, :locale, locale)) do
      {:ok, email}
    else
      {:error, :user_not_found} ->
        {:error, dgettext("errors", "No user to validate with this email was found")}

      {:error, :invalid_email} ->
        {:error, dgettext("errors", "This email doesn't seem to be valid")}

      {:error, :failed_sending_mail} ->
        {:error, dgettext("errors", "Couldn't send an email. Internal error.")}

      {:error, :email_too_soon} ->
        {:error,
         dgettext(
           "errors",
           "You requested again a confirmation email too soon. Please try again in a few minutes"
         )}
    end
  end

  @doc """
  Send an email to reset the password from an user
  """
  def send_reset_password(_parent, args, _resolution) do
    with {:ok, email} <- lowercase_domain(Map.get(args, :email)),
         {:ok, %User{locale: locale} = user} <-
           Users.get_user_by_email(email, activated: true, unconfirmed: false),
         {:can_reset_password, true} <-
           {:can_reset_password, Authenticator.can_reset_password?(user)} do
      Email.User.send_password_reset_email(user, Map.get(args, :locale, locale))
      {:ok, email}
    else
      {:can_reset_password, false} ->
        {:error, dgettext("errors", "This user can't reset their password")}

      {:error, :invalid_email} ->
        {:error, dgettext("errors", "This email doesn't seem to be valid")}

      {:error, :user_not_found} ->
        # TODO : implement rate limits for this endpoint
        {:error, dgettext("errors", "No user with this email was found")}

      {:error, :email_too_soon} ->
        {:error,
         dgettext(
           "errors",
           "You requested again a password reset email too soon. Please try again in a few minutes"
         )}
    end
  end

  @doc """
  Reset the password from an user
  """
  @spec reset_password(map(), %{password: String.t(), token: String.t()}, map()) ::
          {:ok, map()} | {:error, String.t()}
  def reset_password(_parent, %{password: password, token: token}, _resolution) do
    case Email.User.check_reset_password_token(password, token) do
      {:ok, %User{email: email} = user} ->
        {:ok, tokens} = Authenticator.authenticate(email, password)
        {:ok, Map.put(tokens, :user, user)}

      {:error, %Ecto.Changeset{errors: [password: {"registration.error.password_too_short", _}]}} ->
        {:error,
         dgettext(
           "errors",
           "The password you have chosen is too short. Please make sure your password contains at least 6 characters."
         )}

      {:error, _err} ->
        {:error,
         dgettext(
           "errors",
           "The token you provided is invalid. Make sure that the URL is exactly the one provided inside the email you got."
         )}
    end
  end

  @doc "Change an user default actor"
  def change_default_actor(
        _parent,
        %{preferred_username: username},
        %{context: %{current_user: %User{} = user}}
      ) do
    case Actors.get_local_actor_by_name(username) do
      %Actor{id: actor_id} = actor ->
        if actor_id in Enum.map(Users.get_actors_for_user(user), & &1.id) do
          %User{} = user = Users.update_user_default_actor(user, actor)
          {:ok, user}
        else
          {:error, dgettext("errors", "This profile does not belong to you")}
        end

      nil ->
        {:error,
         dgettext("errors", "Profile with username %{username} not found", %{username: username})}
    end
  end

  def change_default_actor(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @doc """
  Returns the list of events for all of this user's identities are going to
  """
  def user_participations(
        %User{id: user_id},
        args,
        %{context: %{current_user: %User{id: logged_user_id, role: role}}}
      ) do
    with true <- user_id == logged_user_id or is_moderator(role),
         %Page{} = page <-
           Events.list_participations_for_user(
             user_id,
             Map.get(args, :after_datetime),
             Map.get(args, :before_datetime),
             Map.get(args, :page),
             Map.get(args, :limit)
           ) do
      {:ok, page}
    end
  end

  @doc """
  Returns the list of groups this user is a member is a member of
  """
  def user_memberships(
        %User{id: user_id},
        %{page: page, limit: limit} = args,
        %{context: %{current_user: %User{id: logged_user_id}}}
      ) do
    with true <- user_id == logged_user_id,
         memberships <-
           Actors.list_memberships_for_user(
             user_id,
             Map.get(args, :name),
             page,
             limit
           ) do
      {:ok, memberships}
    end
  end

  @doc """
  Returns the list of draft events for the current user
  """
  def user_drafted_events(
        %User{id: user_id},
        args,
        %{context: %{current_user: %User{id: logged_user_id}}}
      ) do
    with {:same_user, true} <- {:same_user, user_id == logged_user_id},
         events <-
           Events.list_drafts_for_user(user_id, Map.get(args, :page), Map.get(args, :limit)) do
      {:ok, events}
    end
  end

  def change_password(
        _parent,
        %{old_password: old_password, new_password: new_password},
        %{context: %{current_user: %User{} = user}}
      ) do
    with {:can_change_password, true} <-
           {:can_change_password, Authenticator.can_change_password?(user)},
         {:current_password, {:ok, %User{}}} <-
           {:current_password, Authenticator.login(user.email, old_password)},
         {:same_password, false} <- {:same_password, old_password == new_password},
         {:ok, %User{} = user} <-
           user
           |> User.password_change_changeset(%{"password" => new_password})
           |> Repo.update() do
      {:ok, user}
    else
      {:can_change_password, false} ->
        {:error, dgettext("errors", "You cannot change your password.")}

      {:current_password, _} ->
        {:error, dgettext("errors", "The current password is invalid")}

      {:same_password, true} ->
        {:error, dgettext("errors", "The new password must be different")}

      {:error, %Ecto.Changeset{errors: [password: {"registration.error.password_too_short", _}]}} ->
        {:error,
         dgettext(
           "errors",
           "The password you have chosen is too short. Please make sure your password contains at least 6 characters."
         )}
    end
  end

  def change_password(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to change your password")}
  end

  def change_email(_parent, %{email: new_email, password: password}, %{
        context: %{current_user: %User{email: old_email} = user}
      }) do
    if Authenticator.can_change_email?(user) do
      do_change_mail_can_change_mail(user, old_email, new_email, password)
    else
      {:error, dgettext("errors", "User cannot change email")}
    end
  end

  def change_email(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to change your email")}
  end

  @spec do_change_mail_can_change_mail(User.t(), String.t(), String.t(), String.t()) ::
          {:ok, User.t()} | {:error, String.t()}
  defp do_change_mail_can_change_mail(user, old_email, new_email, password) do
    case Authenticator.login(old_email, password) do
      {:ok, %User{}} ->
        if new_email != old_email do
          do_change_mail_new_email(user, new_email)
        else
          {:error, dgettext("errors", "The new email must be different")}
        end

      {:error, _} ->
        {:error, dgettext("errors", "The password provided is invalid")}
    end
  end

  @spec do_change_mail_new_email(User.t(), String.t()) :: {:ok, User.t()} | {:error, String.t()}
  defp do_change_mail_new_email(user, new_email) do
    if Email.Checker.valid?(new_email) do
      do_change_mail(user, new_email)
    else
      {:error, dgettext("errors", "The new email doesn't seem to be valid")}
    end
  end

  @spec do_change_mail(User.t(), String.t()) :: {:ok, User.t()} | {:error, String.t()}
  defp do_change_mail(user, new_email) do
    case Users.update_user_email(user, new_email) do
      {:ok, %User{} = user} ->
        user
        |> Email.User.send_email_reset_old_email()
        |> Email.Mailer.send_email()

        user
        |> Email.User.send_email_reset_new_email()
        |> Email.Mailer.send_email()

        {:ok, user}

      {:error, %Ecto.Changeset{} = err} ->
        Logger.debug(inspect(err))
        {:error, dgettext("errors", "Failed to update user email")}
    end
  end

  @spec validate_email(map(), %{token: String.t()}, map()) ::
          {:ok, User.t()} | {:error, String.t()}
  def validate_email(_parent, %{token: token}, _resolution) do
    case Users.get_user_by_activation_token(token) do
      %User{} = user ->
        case Users.validate_email(user) do
          {:ok, %User{} = user} ->
            {:ok, user}

          {:error, %Ecto.Changeset{} = err} ->
            Logger.debug(inspect(err))
            {:error, dgettext("errors", "Failed to validate user email")}
        end

      nil ->
        {:error, dgettext("errors", "Invalid activation token")}
    end
  end

  def delete_account(_parent, %{user_id: user_id}, %{
        context: %{
          current_user: %User{role: role},
          current_actor: %Actor{} = moderator_actor
        }
      })
      when is_moderator(role) do
    with %User{disabled: false} = user <- Users.get_user(user_id),
         {:ok, %User{}} <-
           do_delete_account(%User{} = user) do
      Admin.log_action(moderator_actor, "delete", user)
      {:ok, %{id: to_string(user.id)}}
    else
      %User{disabled: true} ->
        {:error, dgettext("errors", "User already disabled")}
    end
  end

  def delete_account(_parent, args, %{
        context: %{current_user: %User{email: email} = user}
      }) do
    with {:user_has_password, true} <- {:user_has_password, Authenticator.has_password?(user)},
         {:confirmation_password, password} when not is_nil(password) <-
           {:confirmation_password, Map.get(args, :password)},
         {:current_password, {:ok, _}} <-
           {:current_password, Authenticator.authenticate(email, password)} do
      do_delete_account(user, reserve_email: false)
    else
      # If the user hasn't got any password (3rd-party auth)
      {:user_has_password, false} ->
        do_delete_account(user, reserve_email: false)

      {:confirmation_password, nil} ->
        {:error, dgettext("errors", "The password provided is invalid")}

      {:current_password, _} ->
        {:error, dgettext("errors", "The password provided is invalid")}
    end
  end

  def delete_account(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to delete your account")}
  end

  @spec do_delete_account(User.t(), Keyword.t()) :: {:ok, User.t()}
  defp do_delete_account(%User{} = user, options \\ []) do
    with actors <- Users.get_actors_for_user(user),
         activated <- not is_nil(user.confirmed_at),
         # Detach actors from user
         :ok <- Enum.each(actors, fn actor -> Actors.update_actor(actor, %{user_id: nil}) end),
         # Launch a background job to delete actors
         :ok <-
           Enum.each(actors, fn actor ->
             actor_performing = Keyword.get(options, :actor_performing, actor)
             Actions.Delete.delete(actor, actor_performing, true)
           end) do
      # Delete user
      Users.delete_user(user, reserve_email: Keyword.get(options, :reserve_email, activated))
    end
  end

  @spec user_settings(User.t(), map(), map()) :: {:ok, list(Setting.t())} | {:error, String.t()}
  def user_settings(%User{} = user, _args, %{
        context: %{current_user: %User{role: role}}
      })
      when is_moderator(role) do
    with {:setting, settings} <- {:setting, Users.get_setting(user)} do
      {:ok, settings}
    end
  end

  def user_settings(%User{id: user_id} = user, _args, %{
        context: %{current_user: %User{id: logged_user_id}}
      }) do
    with {:same_user, true} <- {:same_user, user_id == logged_user_id},
         {:setting, settings} <- {:setting, Users.get_setting(user)} do
      {:ok, settings}
    else
      {:same_user, _} ->
        {:error, dgettext("errors", "User requested is not logged-in")}
    end
  end

  @spec set_user_setting(map(), map(), map()) :: {:ok, Setting.t()} | {:error, any()}
  def set_user_setting(_parent, attrs, %{
        context: %{current_user: %User{id: logged_user_id}}
      }) do
    attrs = Map.put(attrs, :user_id, logged_user_id)

    res =
      case Users.get_setting(logged_user_id) do
        nil ->
          Users.create_setting(attrs)

        %Setting{} = setting ->
          Users.update_setting(setting, attrs)
      end

    case res do
      {:ok, %Setting{} = setting} ->
        {:ok, setting}

      {:error, changeset} ->
        Logger.debug(inspect(changeset))
        {:error, dgettext("errors", "Error while saving user settings")}
    end
  end

  def update_locale(_parent, %{locale: locale}, %{
        context: %{current_user: %User{locale: current_locale} = user}
      }) do
    if current_locale != locale do
      case Users.update_user(user, %{locale: locale}) do
        {:ok, %User{} = updated_user} ->
          {:ok, updated_user}

        {:error, %Ecto.Changeset{} = err} ->
          Logger.debug(err)
          {:error, dgettext("errors", "Error while updating locale")}
      end
    else
      {:ok, user}
    end
  end

  def user_medias(%User{id: user_id}, %{page: page, limit: limit}, %{
        context: %{current_user: %User{id: logged_in_user_id}}
      })
      when user_id == logged_in_user_id do
    %{elements: elements, total: total} = Mobilizon.Medias.medias_for_user(user_id, page, limit)

    {:ok,
     %{
       elements:
         Enum.map(elements, fn element ->
           %{
             name: element.file.name,
             url: element.file.url,
             id: element.id,
             content_type: element.file.content_type,
             size: element.file.size
           }
         end),
       total: total
     }}
  end

  def user_followed_group_events(%User{id: user_id}, %{page: page, limit: limit} = args, %{
        context: %{current_user: %User{id: logged_in_user_id}}
      })
      when user_id == logged_in_user_id do
    activities =
      FollowedGroupActivity.user_followed_group_events(
        user_id,
        Map.get(args, :after_datetime),
        page,
        limit
      )

    activities = %Page{
      activities
      | elements:
          Enum.map(activities.elements, fn [event, group, profile] ->
            %{group: group, profile: profile, event: event}
          end)
    }

    {:ok, activities}
  end

  def user_group_events(%User{id: user_id}, %{page: page, limit: limit} = args, %{
        context: %{current_user: %User{id: logged_in_user_id}}
      })
      when user_id == logged_in_user_id do
    activities =
      Mobilizon.UserGroupEvents.user_group_events(
        user_id,
        Map.get(args, :after_datetime),
        page,
        limit
      )

    activities = %Page{
      activities
      | elements:
          Enum.map(activities.elements, fn [event, group, profile] ->
            %{group: group, profile: profile, event: event}
          end)
    }

    {:ok, activities}
  end

  @spec update_user_login_information(User.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp update_user_login_information(
         %User{current_sign_in_at: current_sign_in_at, current_sign_in_ip: current_sign_in_ip} =
           user,
         context
       ) do
    current_ip = Map.get(context, :ip)
    now = DateTime.utc_now()

    Users.update_user(user, %{
      last_sign_in_at: current_sign_in_at || now,
      last_sign_in_ip: current_sign_in_ip || current_ip,
      current_sign_in_ip: current_ip,
      current_sign_in_at: now
    })
  end

  # Ensures that a user has a default actor. If not, uses existing actor or creates one.
  # This is particularly important for email/password users who don't get a default actor
  # set during registration, unlike OAuth users.
  @spec ensure_user_has_default_actor(User.t()) :: {:ok, User.t()} | {:error, any()}
  defp ensure_user_has_default_actor(%User{default_actor_id: nil, provider: nil} = user) do
    # User registered with email/password and has no default actor
    # First, check if user already has existing actors
    case Users.get_actors_for_user(user) do
      [%Actor{} = first_actor | _] ->
        # User has existing actors - use the first one as default
        Logger.info("Setting existing actor #{first_actor.id} as default for user #{user.email}")
        
        updated_user = Users.update_user_default_actor(user, first_actor)
        {:ok, updated_user}
      
      [] ->
        # User has no actors - create one
        Logger.info("Creating default actor for email/password user #{user.email}")
        
        # Generate a unique username from email
        username = generate_unique_username_from_email(user.email)
        
        case Actors.new_person(%{
          user_id: user.id,
          preferred_username: username,
          name: username,
          summary: ""
        }, true) do  # true = set as default actor
          {:ok, _actor} ->
            # Reload user to get the updated default_actor_id
            case Users.get_user_with_actors(user.id) do
              {:ok, updated_user} ->
                Logger.info("Successfully created default actor for user #{user.email}")
                {:ok, updated_user}
              
              {:error, error} ->
                Logger.error("Failed to reload user after actor creation: #{inspect(error)}")
                {:error, error}
            end
          
          {:error, error} ->
            Logger.error("Failed to create default actor for user #{user.email}: #{inspect(error)}")
            {:error, error}
        end
    end
  end

  defp ensure_user_has_default_actor(%User{} = user) do
    # User already has a default actor or is from external provider
    {:ok, user}
  end

  @spec generate_unique_username_from_email(String.t()) :: String.t()
  defp generate_unique_username_from_email(email) do
    base_username = generate_username_from_email(email)
    
    # Try the base username first
    case Actors.get_local_actor_by_name(base_username) do
      nil -> base_username
      _actor -> 
        # Username is taken, try with random suffix
        generate_unique_username_with_suffix(base_username, 1)
    end
  end

  @spec generate_unique_username_with_suffix(String.t(), integer()) :: String.t()
  defp generate_unique_username_with_suffix(base_username, attempt) when attempt <= 100 do
    # Generate a random 4-digit suffix
    suffix = :rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")
    candidate = "#{base_username}_#{suffix}"
    
    case Actors.get_local_actor_by_name(candidate) do
      nil -> candidate
      _actor -> generate_unique_username_with_suffix(base_username, attempt + 1)
    end
  end

  defp generate_unique_username_with_suffix(_base_username, _attempt) do
    # Fallback after 100 attempts - use timestamp
    "user_#{System.system_time(:second)}"
  end

  @spec generate_username_from_email(String.t()) :: String.t()
  defp generate_username_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "")
    |> String.slice(0, 16)  # Leave room for suffix
    |> case do
      "" -> "user"
      username -> username
    end
  end
end
