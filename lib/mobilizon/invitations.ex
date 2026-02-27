defmodule Mobilizon.Invitations do
  @moduledoc """
  Context for group invitation tokens (invite-by-email flow).

  Tokens are one-time use, time-limited (7 days), and used in email links
  to add a user to a group (either existing user or after registration).
  """
  alias Ecto.Changeset
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Invitations.GroupInvitationToken
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Endpoint

  @token_validity_days 7
  @token_byte_length 32

  @doc """
  Creates a new group invitation token and sends the appropriate email.

  - If a user with the given email exists: creates a Member with role :invited,
    creates a token, sends "join group" email. Token is linked to that member flow.
  - If no user exists and `confirm_non_existing_user` is true: creates only a token,
    sends "register and join group" email.
  - If no user exists and `confirm_non_existing_user` is false: returns error.

  Returns `{:ok, token}` or `{:error, reason}`.
  """
  @spec create_group_invitation(integer | String.t(), String.t(), integer | String.t(), boolean()) ::
          {:ok, GroupInvitationToken.t()}
          | {:error, :user_not_found | :not_eligible | :already_member | Changeset.t()}
  def create_group_invitation(group_id, email, invited_by_id, confirm_non_existing_user) do
    email = String.trim(String.downcase(email))
    with {:ok, group} <- Actors.get_group_by_actor_id(group_id),
         {:ok, inviter} <- get_inviter(invited_by_id),
         :admin <- ensure_inviter_is_admin(inviter.id, group.id),
         {:ok, _} <- ensure_email_not_already_member(group, email) do
      case Users.get_user_by_email(email, activated: true, unconfirmed: false) do
        {:ok, _user} ->
          create_invitation_for_existing_user(group, email, inviter)

        {:error, :user_not_found} ->
          if confirm_non_existing_user do
            create_invitation_for_new_user(group, email, inviter)
          else
            {:error, :user_not_found}
          end
      end
    else
      {:error, :group_not_found} -> {:error, :user_not_found}
      {:error, :actor_not_found} -> {:error, :user_not_found}
      :not_admin -> {:error, :not_eligible}
      {:error, :already_member} = err -> err
      err -> err
    end
  end

  defp get_inviter(invited_by_id) do
    case Actors.get_actor(invited_by_id) do
      nil -> {:error, :actor_not_found}
      inv -> {:ok, inv}
    end
  end

  defp ensure_inviter_is_admin(actor_id, group_id) do
    case Actors.get_member(actor_id, group_id) do
      {:ok, %Member{role: role}} when role in [:administrator, :creator, :moderator] -> :admin
      _ -> :not_admin
    end
  end

  defp ensure_email_not_already_member(%Actor{id: group_id}, email) do
    case Users.get_user_by_email(email, activated: true, unconfirmed: false) do
      {:ok, user} ->
        default_actor_id = user.default_actor_id
        if default_actor_id do
          case Actors.get_member(default_actor_id, group_id) do
            {:ok, %Member{role: role}} when role in [:member, :moderator, :administrator, :creator] ->
              {:error, :already_member}
            _ -> {:ok, :ok}
          end
        else
          {:ok, :ok}
        end
      {:error, :user_not_found} -> {:ok, :ok}
    end
  end

  defp create_invitation_for_existing_user(group, email, inviter) do
    expires_at = DateTime.utc_now() |> DateTime.add(@token_validity_days, :day)
    token_string = generate_token()

    attrs = %{
      token: token_string,
      email: email,
      group_id: group.id,
      invited_by_id: inviter.id,
      expires_at: expires_at,
      for_new_user: false
    }

    with {:ok, inv} <- insert_token(attrs),
         :ok <- Mobilizon.Web.Email.Member.send_group_invite_existing_user(email, inv, group, inviter) do
      {:ok, Repo.preload(inv, [:group, :invited_by])}
    end
  end

  defp create_invitation_for_new_user(group, email, inviter) do
    expires_at = DateTime.utc_now() |> DateTime.add(@token_validity_days, :day)
    token_string = generate_token()

    attrs = %{
      token: token_string,
      email: email,
      group_id: group.id,
      invited_by_id: inviter.id,
      expires_at: expires_at,
      for_new_user: true
    }

    with {:ok, inv} <- insert_token(attrs),
         :ok <- Mobilizon.Web.Email.Member.send_group_invite_new_user(email, inv, group, inviter) do
      {:ok, Repo.preload(inv, [:group, :invited_by])}
    end
  end

  defp insert_token(attrs) do
    %GroupInvitationToken{}
    |> GroupInvitationToken.changeset(attrs)
    |> Repo.insert()
  end

  defp generate_token do
    @token_byte_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Returns the invitation URL for a token (for use in emails).
  """
  def invitation_url(%GroupInvitationToken{token: token}) do
    Endpoint.url() <> "/invitations/accept/" <> token
  end

  @doc """
  Fetches an invitation by token. Returns the token struct if valid (not used, not expired).
  """
  @spec get_invitation_by_token(String.t()) ::
          {:ok, GroupInvitationToken.t()} | {:error, :not_found | :expired | :already_used}
  def get_invitation_by_token(token) when is_binary(token) do
    case Repo.get_by(GroupInvitationToken, token: token) |> Repo.preload([:group, :invited_by]) do
      nil -> {:error, :not_found}
      %{used_at: %DateTime{}} -> {:error, :already_used}
      %{expires_at: expires_at} = inv when not is_nil(expires_at) ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:ok, inv}
        else
          {:error, :expired}
        end
      inv -> {:ok, inv}
    end
  end

  @doc """
  Marks the invitation token as used and adds the given actor to the group as a member.

  Call this when the user has clicked the link and is logged in (or just registered).
  Returns {:ok, member} or {:error, reason}.
  """
  @spec use_invitation_token(String.t(), Actor.t()) ::
          {:ok, Member.t()} | {:error, :not_found | :expired | :already_used | :email_mismatch}
  def use_invitation_token(token, %Actor{id: actor_id} = _actor) when is_binary(token) do
    with {:ok, inv} <- get_invitation_by_token(token),
         {:ok, user} <- user_by_actor_id(actor_id),
         :ok <- ensure_email_matches(user, inv.email),
         {:ok, _} <- mark_used(inv),
         {:ok, member} <- add_actor_to_group(inv.group_id, actor_id, inv.invited_by_id) do
      {:ok, member}
    else
      {:error, :user_not_found} -> {:error, :email_mismatch}
      {:error, :email_mismatch} = e -> e
      e -> e
    end
  end

  defp user_by_actor_id(actor_id) do
    case Users.get_user_by_default_actor_id(actor_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp ensure_email_matches(%User{email: user_email}, invitation_email) do
    if String.downcase(user_email) == String.downcase(invitation_email) do
      :ok
    else
      {:error, :email_mismatch}
    end
  end

  defp mark_used(%GroupInvitationToken{} = inv) do
    inv
    |> Changeset.change(%{used_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  defp add_actor_to_group(group_id, actor_id, invited_by_id) do
    Actors.create_member(%{
      parent_id: group_id,
      actor_id: actor_id,
      role: :member,
      invited_by_id: invited_by_id,
      url: nil
    })
  end
end
