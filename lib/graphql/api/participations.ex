defmodule Mobilizon.GraphQL.API.Participations do
  @moduledoc """
  Common API to join events and groups.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub.{Actions, Activity}
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Web.Email.Participation

  @spec join(Event.t(), Actor.t(), map()) ::
          {:ok, Activity.t(), Participant.t()} | {:error, :already_participant}
  def join(%Event{id: event_id} = event, %Actor{id: actor_id} = actor, args \\ %{}) do
    case Mobilizon.Events.get_participant(event_id, actor_id, args) do
      {:ok, %Participant{}} ->
        {:error, :already_participant}

      {:error, :participant_not_found} ->
        Actions.Join.join(event, actor, Map.get(args, :local, true), %{metadata: args})
    end
  end

  @spec leave(Event.t(), Actor.t(), map()) ::
          {:ok, Activity.t(), Participant.t()}
          | {:error, :is_only_organizer | :participant_not_found | Ecto.Changeset.t()}
  def leave(%Event{} = event, %Actor{} = actor, args \\ %{}),
    do: Actions.Leave.leave(event, actor, Map.get(args, :local, true), %{metadata: args})

  @doc """
  Update participation status
  """
  @spec update(Participant.t(), Actor.t(), atom()) ::
          {:ok, Activity.t(), Participant.t()} | {:error, Ecto.Changeset.t()}
  def update(%Participant{} = participation, %Actor{} = moderator, :participant),
    do: accept(participation, moderator)

  def update(%Participant{} = participation, %Actor{} = _moderator, :not_approved) do
    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participation, %{role: :not_approved}) do
      Scheduler.pending_participation_notification(participation.event)
      {:ok, nil, participant}
    end
  end

  def update(%Participant{} = participation, %Actor{} = moderator, :rejected) do
    result = reject(participation, moderator)
    # When we reject a participant, check if we can promote someone from waitlist
    Task.start(fn -> promote_from_waitlist_if_needed(participation.event_id) end)
    result
  end

  @spec accept(Participant.t(), Actor.t()) ::
          {:ok, Activity.t(), Participant.t()} | {:error, Ecto.Changeset.t()}
  defp accept(
         %Participant{} = participation,
         %Actor{} = moderator
       ) do
    case Actions.Accept.accept(
           :join,
           participation,
           true,
           %{"actor" => moderator.url}
         ) do
      {:ok, activity, %Participant{role: :participant} = participation} ->
        Participation.send_emails_to_local_user(participation)
        {:ok, activity, participation}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec reject(Participant.t(), Actor.t()) :: {:ok, Activity.t(), Participant.t()}
  defp reject(
         %Participant{} = participation,
         %Actor{} = moderator
       ) do
    with {:ok, activity, %Participant{role: :rejected} = participation} <-
           Actions.Reject.reject(
             :join,
             participation,
             true,
             %{"actor" => moderator.url}
           ),
         :ok <- Participation.send_emails_to_local_user(participation) do
      {:ok, activity, participation}
    end
  end

  @doc """
  Automatically promote the next participant from waitlist if there's an available spot
  """
  @spec promote_from_waitlist_if_needed(integer) :: :ok
  def promote_from_waitlist_if_needed(event_id) do
    with {:ok, event} <- Events.get_event_with_preload(event_id),
         true <- event.options.enable_waitlist,
         true <- event.options.maximum_attendee_capacity > 0,
         current_participant_count <-
           Events.count_participants_by_role(event_id, [
             :participant,
             :creator,
             :administrator,
             :moderator
           ]),
         true <- current_participant_count < event.options.maximum_attendee_capacity do
      # Get the first person from waitlist (ordered by insertion time)
      case Events.list_participants_for_event(event_id, [:waitlist], 1, 1) do
        %{elements: [waitlist_participant]} ->
          # Promote them to participant
          case Events.update_participant(waitlist_participant, %{role: :participant}) do
            {:ok, updated_participant} ->
              # Send notification email
              Participation.send_emails_to_local_user(updated_participant)

              Logger.info(
                "Promoted participant #{updated_participant.id} from waitlist to participant for event #{event_id}"
              )

            {:error, reason} ->
              Logger.warn("Failed to promote waitlist participant: #{inspect(reason)}")
          end

        _ ->
          # No one on waitlist
          :ok
      end
    else
      _ -> :ok
    end
  end
end
