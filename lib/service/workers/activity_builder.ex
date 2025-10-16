defmodule Mobilizon.Service.Workers.ActivityBuilder do
  @moduledoc """
  Worker to insert activity items in users feeds
  """

  alias Mobilizon.{Activities, Actors, Users}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Users.User

  use Mobilizon.Service.Workers.Helper, queue: "activity"

  @impl Oban.Worker
  @spec perform(Job.t()) :: {:ok, Activity.t()} | {:error, Ecto.Changeset.t()}
  def perform(%Job{args: args}) do
    {"build_activity", args} = Map.pop(args, "op")

    case build_activity(args) do
      {:ok, %Activity{} = activity} ->
        activity
        |> Activities.preload_activity()
        |> notify_activity()

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec build_activity(map()) :: {:ok, Activity.t()} | {:error, Ecto.Changeset.t()}
  def build_activity(args) do
    Activities.create_activity(args)
  end

  @spec notify_activity(Activity.t()) :: :ok
  def notify_activity(%Activity{subject: subject} = activity) do
    require Logger
    Logger.info("notify_activity called for subject: #{subject}")

    users = users_to_notify(activity)
    Logger.info("Found #{length(users)} users to notify for activity #{subject}")

    users
    |> Enum.each(fn user ->
      Logger.info("Notifying user #{user.id} (#{user.email}) for activity #{subject}")
      Notifier.notify(user, activity, single_activity: true)
    end)

    :ok
  end

  @spec users_to_notify(Activity.t()) :: list(User.t())
  defp users_to_notify(%Activity{
         group: %Actor{type: :Group, id: group_id} = group,
         author_id: author_id,
         subject: subject
       }) do
    require Logger

    Logger.info(
      "users_to_notify: Looking for members in group #{group_id} for subject #{subject}"
    )

    members =
      Actors.list_internal_actors_members_for_group(group, [
        :creator,
        :administrator,
        :moderator,
        :member
      ])

    Logger.info("Found #{length(members)} members in group #{group_id}")

    filtered_members = Enum.filter(members, &(&1.id != author_id))
    Logger.info("After filtering author #{author_id}: #{length(filtered_members)} members")

    user_ids =
      filtered_members
      |> Enum.map(& &1.user_id)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    Logger.info("Found #{length(user_ids)} unique user IDs: #{inspect(user_ids)}")

    users = Enum.map(user_ids, &Users.get_user_with_activity_settings!/1)
    Logger.info("Retrieved #{length(users)} users with activity settings")

    users
  end

  defp users_to_notify(%Activity{} = activity),
    do:
      (
        require Logger

        Logger.info(
          "users_to_notify: Activity doesn't have group or not matching pattern: #{inspect(activity, pretty: true)}"
        )

        []
      )
end
