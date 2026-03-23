defmodule Mobilizon.Events.PendingGroupApproval do
  @moduledoc false

  import Ecto.Query
  import Ecto.Changeset, only: [change: 2]

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Types.Events, as: EventPubTypes
  alias Mobilizon.Service.Export.Cachable
  alias Mobilizon.Service.Search.BuildSearch
  alias Mobilizon.Service.Workers.EventDelayedNotificationWorker
  alias Mobilizon.Storage.Repo

  import Mobilizon.Events.Utils, only: [calculate_notification_time: 1]

  require Logger

  @doc """
  Clears `pending_group_approval` on events for a group after instance admins approve the group.
  Enqueues search, notifications, and federation similarly to initial publication.
  """
  @spec release_events_for_approved_group(integer() | String.t()) :: :ok
  def release_events_for_approved_group(group_id) when is_integer(group_id) do
    from(e in Event,
      where: e.attributed_to_id == ^group_id and e.pending_group_approval == true
    )
    |> Repo.all()
    |> Enum.each(&release_one_event/1)

    :ok
  end

  def release_events_for_approved_group(group_id) when is_binary(group_id) do
    case Integer.parse(group_id) do
      {int, ""} ->
        release_events_for_approved_group(int)

      _ ->
        Logger.warning("release_events_for_approved_group: invalid group id #{inspect(group_id)}")
        :ok
    end
  end

  defp release_one_event(%Event{} = event) do
    # Do not use Event.update_changeset/2: common_changeset always does
    # put_assoc(:contacts, []) / put_assoc(:media, []), which requires preloads.
    changeset = change(event, %{pending_group_approval: false})

    case Repo.update(changeset) do
      {:ok, updated} ->
        try do
          run_release_side_effects(updated)
        rescue
          e ->
            Logger.error(
              "Pending group release: post-update steps failed for event #{updated.uuid}: " <>
                Exception.format(:error, e, __STACKTRACE__)
            )
        end

      {:error, changeset} ->
        Logger.warning("Failed to release pending group event #{event.id}: #{inspect(changeset.errors)}")
    end
  end

  defp run_release_side_effects(%Event{} = updated) do
    full_event = Events.get_event_by_uuid_with_preload(updated.uuid) || updated
    Cachable.clear_all_caches(full_event)

    unless full_event.draft do
      BuildSearch.enqueue(:insert_search_event, %{"event_id" => full_event.id})

      %{action: :notify_of_new_event, event_uuid: full_event.uuid}
      |> EventDelayedNotificationWorker.new(
        scheduled_at: calculate_notification_time(full_event.begins_on)
      )
      |> Oban.insert()
    end

    EventPubTypes.federate_create_on_release(full_event)
  end
end
