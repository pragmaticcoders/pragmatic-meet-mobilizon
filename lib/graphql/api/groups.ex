defmodule Mobilizon.GraphQL.API.Groups do
  @moduledoc """
  API for Groups.
  """

  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users
  alias Mobilizon.GraphQL.Error
  alias Mobilizon.Federation.ActivityPub.{Actions, Activity}
  alias Mobilizon.Service.Formatter.HTML
  alias Mobilizon.Web.Email.Admin

  @doc """
  Create a group
  """
  @spec create_group(map) ::
          {:ok, Activity.t(), Actor.t()}
          | {:error, String.t() | Ecto.Changeset.t()}
  def create_group(args) do
    preferred_username =
      args |> Map.get(:preferred_username) |> HTML.strip_tags() |> String.trim()

    args = 
      args 
      |> Map.put(:type, :Group)
      |> Map.put(:approval_status, :pending_approval)

    case Actors.get_local_actor_by_name(preferred_username) do
      nil ->
        case Actions.Create.create(:actor, args, true, %{"actor" => args.creator_actor.url}) do
          {:ok, activity, %Actor{type: :Group} = group} ->
            # Send notification to admins about the new group
            Admin.notify_admins_of_new_group(group)
            {:ok, activity, group}

          error ->
            error
        end

      %Actor{} ->
        {:error,
         %Error{
           code: :validation,
           message: dgettext("errors", "A profile or group with that name already exists"),
           status_code: 409,
           field: "preferred_username"
         }}
    end
  end

  @spec update_group(map) ::
          {:ok, Activity.t(), Actor.t()} | {:error, :group_not_found | Ecto.Changeset.t() | String.t()}
  def update_group(%{id: id, updater_actor: updater_actor} = args) do
    with {:ok, %Actor{type: :Group} = group} <- Actors.get_group_by_actor_id(id),
         {:ok, user} <- get_user_from_actor(updater_actor) do
      if group_update_allowed?(group, user) do
        Actions.Update.update(group, args, true, %{"actor" => args.updater_actor.url})
      else
        {:error, get_unapproved_group_error_message(group)}
      end
    else
      error -> error
    end
  end

  # Helper to get user from actor
  defp get_user_from_actor(%Actor{user: %Users.User{} = user}), do: {:ok, user}
  defp get_user_from_actor(%Actor{id: actor_id}) do
    case Actors.get_actor_with_preload(actor_id) do
      %Actor{user: %Users.User{} = user} -> {:ok, user}
      _ -> {:error, "User not found"}
    end
  end

  # Helper to check if group update is allowed
  defp group_update_allowed?(%Actor{type: :Group, approval_status: :approved, suspended: false}, _user), do: true
  defp group_update_allowed?(_group, %Users.User{role: role}) when role in [:administrator, :moderator], do: true
  defp group_update_allowed?(_group, _user), do: false

  # Helper to get appropriate error message
  defp get_unapproved_group_error_message(%Actor{approval_status: :pending_approval}) do
    dgettext("errors", "This group is pending approval from an administrator. You cannot update the group until it is approved.")
  end
  defp get_unapproved_group_error_message(%Actor{approval_status: :rejected}) do
    dgettext("errors", "This group has been rejected by administrators.")
  end
  defp get_unapproved_group_error_message(%Actor{suspended: true}) do
    dgettext("errors", "This group has been suspended.")
  end
  defp get_unapproved_group_error_message(_group) do
    dgettext("errors", "You cannot update this group.")
  end
end
