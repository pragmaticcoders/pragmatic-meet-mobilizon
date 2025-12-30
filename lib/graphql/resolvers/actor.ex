defmodule Mobilizon.GraphQL.Resolvers.Actor do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Actors, Admin, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Service.Workers.Background
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext, only: [dgettext: 2]

  require Logger

  @spec refresh_profile(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def refresh_profile(_parent, %{id: id}, %{context: %{current_user: %User{role: role}}})
      when is_admin(role) do
    case Actors.get_actor(id) do
      %Actor{domain: domain, id: actor_id} = actor when not is_nil(domain) ->
        Background.enqueue("refresh_profile", %{
          "actor_id" => actor_id
        })

        {:ok, actor}

      %Actor{} ->
        {:error, dgettext("errors", "Only remote profiles may be refreshed")}

      _ ->
        {:error, dgettext("errors", "No profile found with this ID")}
    end
  end

  @doc """
  Suspend an actor:
  - Local Person actors cannot be suspended directly - use suspendUser instead
  - Remote Person actors can be suspended (deletes local copy)
  - Local Groups are soft-suspended (preserves data, blocks access)
  - Remote Groups are deleted from local instance
  """
  @spec suspend_profile(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def suspend_profile(_parent, %{id: id}, %{
        context: %{
          current_user: %User{role: role},
          current_actor: %Actor{} = moderator_actor
        }
      })
      when is_moderator(role) do
    case Actors.get_actor_with_preload(id) do
      # Local Person actors cannot be suspended - must suspend the User account
      %Actor{type: :Person, domain: nil} ->
        {:error, dgettext("errors", "Local profiles cannot be suspended directly. Suspend the user account instead.")}

      # Soft suspend a local group (preserve data, just set flag)
      %Actor{suspended: false, type: :Group, domain: nil} = actor ->
        Logger.debug("Soft suspending a local group")
        with {:ok, %Actor{} = updated_actor} <- Actors.update_actor(actor, %{suspended: true}),
             {:ok, _} <- Admin.log_action(moderator_actor, "suspend", actor) do
          {:ok, updated_actor}
        end

      # Remote actors (Person or Group) - delete local copy
      %Actor{suspended: false, domain: domain} = actor when not is_nil(domain) ->
        Logger.debug("Deleting remote actor #{actor.preferred_username}@#{domain} from local instance")
        Actors.delete_actor(actor, suspension: true)
        Admin.log_action(moderator_actor, "suspend", actor)
        {:ok, actor}

      %Actor{suspended: true} ->
        {:error, dgettext("errors", "Profile already suspended")}

      nil ->
        {:error, dgettext("errors", "Profile not found")}
    end
  end

  def suspend_profile(_parent, _args, _resolution) do
    {:error, dgettext("errors", "Only moderators and administrators can suspend a profile")}
  end

  @doc """
  Permanently delete a Group and all its data (admin/moderator only).
  """
  @spec admin_delete_group(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def admin_delete_group(_parent, %{id: id}, %{
        context: %{
          current_user: %User{role: role},
          current_actor: %Actor{} = moderator_actor
        }
      })
      when is_moderator(role) do
    case Actors.get_actor_with_preload(id, true) do
      %Actor{type: :Group, domain: nil} = actor ->
        Logger.info("Permanently deleting local group #{actor.preferred_username}")
        Actions.Delete.delete(actor, moderator_actor, true, %{suspension: true})
        Admin.log_action(moderator_actor, "delete", actor)
        {:ok, %{id: to_string(id)}}

      %Actor{type: :Group, domain: domain} when not is_nil(domain) ->
        {:error, dgettext("errors", "Remote groups cannot be permanently deleted, only suspended")}

      %Actor{type: :Person} ->
        {:error, dgettext("errors", "Use deleteAccount to delete user profiles")}

      nil ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  def admin_delete_group(_parent, _args, _resolution) do
    {:error, dgettext("errors", "Only moderators and administrators can delete a group")}
  end

  @spec unsuspend_profile(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Actor.t()} | {:error, String.t()}
  def unsuspend_profile(_parent, %{id: id}, %{
        context: %{
          current_user: %User{role: role},
          current_actor: %Actor{} = moderator_actor
        }
      })
      when is_moderator(role) do
    case Actors.get_actor_with_preload(id, true) do
      %Actor{suspended: true} = actor ->
        with {:delete_tombstones, {_, nil}} <-
               {:delete_tombstones, Mobilizon.Tombstone.delete_actor_tombstones(id)},
             # Build updates including restoring user_id if it was cleared during old-style suspension
             actor_updates <- build_unsuspend_updates(actor),
             {:ok, %Actor{} = updated_actor} <- Actors.update_actor(actor, actor_updates),
             :ok <- refresh_if_remote(updated_actor),
             {:ok, _} <- Admin.log_action(moderator_actor, "unsuspend", updated_actor) do
          {:ok, updated_actor}
        else
          {:error, _} ->
            {:error, dgettext("errors", "Error while performing background task")}
        end

      %Actor{suspended: false} ->
        {:error, dgettext("errors", "Profile is not suspended")}

      nil ->
        {:error, dgettext("errors", "No remote profile found with this ID")}
    end
  end

  def unsuspend_profile(_parent, _args, _resolution) do
    {:error, dgettext("errors", "Only moderators and administrators can unsuspend a profile")}
  end

  # Build the updates map for unsuspension, restoring user_id if it was cleared
  @spec build_unsuspend_updates(Actor.t()) :: map()
  defp build_unsuspend_updates(%Actor{id: actor_id, user_id: nil, type: :Person}) do
    # Try to find the original user by looking for a user whose default_actor_id matches this actor
    case Users.get_user_by_default_actor_id(actor_id) do
      %User{id: user_id} ->
        Logger.info("Restoring user_id #{user_id} for actor #{actor_id} during unsuspension")
        %{suspended: false, user_id: user_id}

      nil ->
        Logger.debug("No user found with default_actor_id #{actor_id}, cannot restore user_id")
        %{suspended: false}
    end
  end

  defp build_unsuspend_updates(%Actor{}) do
    %{suspended: false}
  end

  @spec refresh_if_remote(Actor.t()) :: :ok
  defp refresh_if_remote(%Actor{domain: nil}), do: :ok

  defp refresh_if_remote(%Actor{id: actor_id}) do
    Background.enqueue("refresh_profile", %{
      "actor_id" => actor_id
    })

    :ok
  end
end
