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
          {:ok, Activity.t(), Participant.t()}
          | {:ok, Activity.t(), Participant.t(), :waitlist}
          | {:error, :already_participant}
  def join(%Event{id: event_id} = event, %Actor{id: actor_id} = actor, args \\ %{}) do
    case Mobilizon.Events.get_participant(event_id, actor_id, args) do
      {:ok, %Participant{}} ->
        {:error, :already_participant}

      {:error, :participant_not_found} ->
        case Actions.Join.join(event, actor, Map.get(args, :local, true), %{metadata: args}) do
          {:ok, activity, participant, :waitlist} = result ->
            # User joined the waitlist - send notification email
            Logger.info(
              "User #{actor_id} joined waitlist for event #{event_id}, sending notification email"
            )

            # Ensure event is loaded for email template
            participant_with_event = Map.put(participant, :event, event)

            # Send "joined waitlist" email (different from "moved to waitlist")
            case participant_with_event do
              %Participant{actor: %Actor{user_id: user_id}} when not is_nil(user_id) ->
                with %Mobilizon.Users.User{locale: locale} = user <-
                       Mobilizon.Users.get_user!(user_id) do
                  user
                  |> Participation.participation_joined_waitlist(participant_with_event, locale)
                  |> Mobilizon.Web.Email.Mailer.send_email()
                end

              %Participant{actor: %Actor{user_id: nil, id: actor_id}} ->
                if actor_id == Mobilizon.Config.anonymous_actor_id() do
                  %{email: email, locale: locale} = Map.get(participant_with_event, :metadata)
                  locale = locale || "en"

                  email
                  |> Participation.participation_joined_waitlist(participant_with_event, locale)
                  |> Mobilizon.Web.Email.Mailer.send_email()
                end
            end

            # Auto-join the group if the event belongs to a group
            auto_join_event_group(event, actor)

            # Notify group administrators/moderators about waitlist join
            notify_group_admins_of_new_participant(event, participant, :waitlist)

            result

          {:ok, activity, participant} = result ->
            # Regular participation - auto-join the group if the event belongs to a group
            auto_join_event_group(event, actor)

            # Notify group administrators/moderators
            notify_group_admins_of_new_participant(event, participant)

            result

          other_result ->
            other_result
        end
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
  Automatically add actor to group if the event belongs to a group and the actor is not already a member.
  """
  @spec auto_join_event_group(Event.t(), Actor.t()) :: :ok
  defp auto_join_event_group(%Event{attributed_to_id: nil}, _actor) do
    # Event is not attributed to a group, skip
    :ok
  end

  defp auto_join_event_group(
         %Event{attributed_to_id: group_id} = event,
         %Actor{id: actor_id} = _actor
       ) do
    Logger.info(
      "Checking if actor #{actor_id} should be auto-added to group #{group_id} for event #{event.id}"
    )

    # Check if actor is already a member of the group
    case Mobilizon.Actors.member?(actor_id, group_id) do
      true ->
        Logger.info("Actor #{actor_id} is already a member of group #{group_id}")
        :ok

      false ->
        # Get the group to verify it exists
        case Mobilizon.Actors.get_actor(group_id) do
          %Actor{type: :Group} = _group ->
            # When auto-joining via event participation, always use :member role
            # This bypasses normal group joining approval requirements
            role = :member

            Logger.info(
              "Auto-adding actor #{actor_id} to group #{group_id} with role #{role} (via event participation)"
            )

            # Create the membership (URL will be auto-generated by the Member changeset)
            case Mobilizon.Actors.create_member(%{
                   role: role,
                   parent_id: group_id,
                   actor_id: actor_id
                 }) do
              {:ok, member} ->
                Logger.info("✅ Successfully auto-added actor #{actor_id} to group #{group_id}")

                {:ok, member}

              {:error, reason} ->
                Logger.error(
                  "❌ Failed to auto-add actor #{actor_id} to group #{group_id}: #{inspect(reason)}"
                )

                :ok
            end

          _ ->
            Logger.warning("Group #{group_id} not found or is not a group")
            :ok
        end
    end
  end

  @doc """
  Automatically promote participants from waitlist if there are available spots.
  Only promotes automatically if waitlist_auto_promote is enabled.
  Promotes multiple participants if multiple spots are available.
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
         available_spots <- event.options.maximum_attendee_capacity - current_participant_count,
         {:spots_available, true} <- {:spots_available, available_spots > 0} do
      Logger.info(
        "Event #{event_id}: capacity=#{event.options.maximum_attendee_capacity}, current=#{current_participant_count}, available spots=#{available_spots}, checking waitlist..."
      )

      # Get waitlist participants up to the number of available spots (ordered by insertion time)
      case Events.list_participants_for_event(event_id, [:waitlist], available_spots, 1) do
        %{elements: waitlist_participants} when length(waitlist_participants) > 0 ->
          Logger.info(
            "Found #{length(waitlist_participants)} waitlist participant(s), promoting..."
          )

          # Promote all waitlist participants to fill available spots
          promoted_count =
            Enum.reduce(waitlist_participants, 0, fn waitlist_participant, count ->
              Logger.info("Promoting participant #{waitlist_participant.id} from waitlist...")

              case Events.update_participant(waitlist_participant, %{role: :participant}) do
                {:ok, updated_participant} ->
                  # Ensure event is loaded on participant for email template
                  participant_with_event = Map.put(updated_participant, :event, event)

                  # Send notification email
                  Participation.send_emails_to_local_user(participant_with_event)

                  Logger.info(
                    "✅ Successfully promoted participant #{updated_participant.id} from waitlist"
                  )

                  count + 1

                {:error, reason} ->
                  Logger.error(
                    "❌ Failed to promote participant #{waitlist_participant.id}: #{inspect(reason)}"
                  )

                  count
              end
            end)

          Logger.info(
            "✅ Promoted #{promoted_count}/#{available_spots} participant(s) from waitlist for event #{event_id}"
          )

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

      {:spots_available, false} ->
        Logger.info("Event #{event_id}: no available spots (event at capacity)")
        :ok

      other ->
        Logger.warn("Event #{event_id}: unexpected condition #{inspect(other)}")
        :ok
    end
  end

  @doc """
  Notify group administrators and moderators when someone joins an event or waitlist.
  Only sends notifications if the event is attributed to a group.
  """
  @spec notify_group_admins_of_new_participant(Event.t(), Participant.t(), atom()) :: :ok
  def notify_group_admins_of_new_participant(
        event,
        participant,
        participation_type \\ :participant
      )

  def notify_group_admins_of_new_participant(
        %Event{attributed_to_id: group_id} = event,
        %Participant{} = participant,
        participation_type
      )
      when not is_nil(group_id) do
    Logger.info(
      "Notifying group #{group_id} administrators about new #{participation_type} for event #{event.id}"
    )

    # Get the group actor and then its administrators/moderators
    with %Actor{type: :Group} = group <- Mobilizon.Actors.get_actor(group_id) do
      group
      |> Mobilizon.Actors.list_members_for_group(
        nil,
        [:administrator, :moderator, :creator],
        1,
        100
      )
      |> Map.get(:elements, [])
      |> Enum.filter(fn %Mobilizon.Actors.Member{actor: actor} ->
        # Only notify local users (those with user_id)
        not is_nil(actor.user_id)
      end)
      |> Enum.each(fn %Mobilizon.Actors.Member{actor: %Actor{user_id: user_id}} ->
        with %Mobilizon.Users.User{} = user <- Mobilizon.Users.get_user!(user_id) do
          Mobilizon.Web.Email.Participation.notify_admin_of_new_participation(
            user,
            event,
            participant,
            participation_type
          )
          |> Mobilizon.Web.Email.Mailer.send_email()

          Logger.info("Sent notification to group admin user #{user_id}")
        end
      end)
    end

    :ok
  end

  def notify_group_admins_of_new_participant(%Event{}, %Participant{}, _participation_type) do
    # Event is not attributed to a group, skip notification
    :ok
  end
end
