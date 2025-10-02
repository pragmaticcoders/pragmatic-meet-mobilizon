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

  require Logger

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
  def leave(%Event{id: event_id} = event, %Actor{} = actor, args \\ %{}) do
    case Actions.Leave.leave(event, actor, Map.get(args, :local, true), %{metadata: args}) do
      {:ok, activity, participant} = result ->
        # When someone leaves, check if we can promote someone from waitlist
        Task.start(fn -> promote_from_waitlist_if_needed(event_id) end)
        result

      error ->
        error
    end
  end

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
    Logger.info(
      "Rejecting participant #{participation.id} (role: #{participation.role}) from event #{participation.event_id}"
    )

    case reject(participation, moderator) do
      {:ok, activity, %Participant{} = participant} = result ->
        # When we reject a participant, check if we can promote someone from waitlist
        # We do this AFTER the rejection is complete to ensure the database is updated
        Task.start(fn ->
          # Small delay to ensure database transaction is committed
          Process.sleep(100)
          promote_from_waitlist_if_needed(participation.event_id)
        end)

        result

      error ->
        error
    end
  end

  def update(%Participant{role: old_role} = participation, %Actor{} = _moderator, :waitlist) do
    Logger.info(
      "Moving participant #{participation.id} (role: #{old_role}) to waitlist for event #{participation.event_id}"
    )

    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participation, %{role: :waitlist}),
         {:ok, event} <- Events.get_event_with_preload(participation.event_id) do
      # Ensure event is loaded on participant for email template
      participant_with_event = Map.put(participant, :event, event)

      Logger.info(
        "Sending waitlist email to participant #{participant.id}, event: #{event.title}, role: #{participant_with_event.role}"
      )

      # Send notification email
      result = Participation.send_emails_to_local_user(participant_with_event)

      Logger.info("Email send result: #{inspect(result)}")

      # If the participant was previously approved (:participant role), free up the spot
      # and trigger auto-promotion if enabled
      if old_role in [:participant, :moderator, :administrator] do
        Task.start(fn ->
          # Small delay to ensure database transaction is committed
          Process.sleep(100)
          promote_from_waitlist_if_needed(participation.event_id)
        end)
      end

      {:ok, nil, participant}
    end
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
  Automatically promote the next participant from waitlist if there's an available spot.
  Only promotes automatically if waitlist_auto_promote is enabled.
  """
  @spec promote_from_waitlist_if_needed(integer) :: :ok
  def promote_from_waitlist_if_needed(event_id) do
    Logger.info("promote_from_waitlist_if_needed called for event #{event_id}")

    with {:event, {:ok, event}} <- {:event, Events.get_event_with_preload(event_id)},
         {:waitlist_enabled, true} <- {:waitlist_enabled, event.options.enable_waitlist},
         {:auto_promote, true} <-
           {:auto_promote, Map.get(event.options, :waitlist_auto_promote, true)},
         {:has_capacity, true} <-
           {:has_capacity, event.options.maximum_attendee_capacity > 0},
         current_participant_count <-
           Events.count_participants_by_role(event_id, [
             :participant,
             :administrator,
             :moderator
           ]),
         {:spot_available, true} <-
           {:spot_available,
            current_participant_count < event.options.maximum_attendee_capacity} do
      Logger.info(
        "Event #{event_id}: capacity=#{event.options.maximum_attendee_capacity}, current=#{current_participant_count}, checking waitlist..."
      )

      # Get the first person from waitlist (ordered by insertion time)
      case Events.list_participants_for_event(event_id, [:waitlist], 1, 1) do
        %{elements: [waitlist_participant]} ->
          Logger.info("Found waitlist participant #{waitlist_participant.id}, promoting...")

          # Promote them to participant
          case Events.update_participant(waitlist_participant, %{role: :participant}) do
            {:ok, updated_participant} ->
              # Ensure event is loaded on participant for email template
              participant_with_event = Map.put(updated_participant, :event, event)

              # Send notification email
              Participation.send_emails_to_local_user(participant_with_event)

              Logger.info(
                "✅ Successfully promoted participant #{updated_participant.id} from waitlist to participant for event #{event_id}"
              )

            {:error, reason} ->
              Logger.error("❌ Failed to promote waitlist participant: #{inspect(reason)}")
          end

        _ ->
          Logger.info("No participants in waitlist for event #{event_id}")
          :ok
      end
    else
      {:event, _} ->
        Logger.warn("Event #{event_id} not found")
        :ok

      {:waitlist_enabled, false} ->
        Logger.info("Event #{event_id}: waitlist not enabled")
        :ok

      {:auto_promote, false} ->
        Logger.info("Event #{event_id}: auto-promote disabled (manual mode)")
        :ok

      {:has_capacity, false} ->
        Logger.info("Event #{event_id}: no maximum capacity set")
        :ok

      {:spot_available, false} ->
        Logger.info("Event #{event_id}: no available spots (still at capacity)")
        :ok

      other ->
        Logger.warn("Event #{event_id}: unexpected condition #{inspect(other)}")
        :ok
    end
  end
end
