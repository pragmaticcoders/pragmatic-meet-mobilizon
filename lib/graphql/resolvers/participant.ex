defmodule Mobilizon.GraphQL.Resolvers.Participant do
  @moduledoc """
  Handles the participation-related GraphQL calls.
  """
  alias Mobilizon.{Actors, Config, Conversations, Crypto, Events}
  alias Mobilizon.Service.Plugins.Surveys
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.{Conversation, ConversationView}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.GraphQL.API.Comments
  alias Mobilizon.GraphQL.API.Participations
  alias Mobilizon.Service.Export.Participants.{CSV, ODS, PDF}
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email
  alias Mobilizon.Web.Email.Checker
  require Logger
  import Mobilizon.Web.Gettext
  import Mobilizon.GraphQL.Resolvers.Event.Utils

  @doc """
  Join an event for an regular or anonymous actor
  """
  @spec actor_join_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Participant.t()} | {:error, String.t()}
  def actor_join_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id} = args,
        %{context: %{current_user: %User{} = user}}
      ) do
    case User.owns_actor(user, actor_id) do
      {:is_owned, %Actor{} = actor} ->
        if Surveys.enabled?() do
          # Load the event to get its UUID — the stable public identifier used as context_id.
          # Using the raw event_id from GraphQL args would produce a different context_id than
          # the one saved by the event resolver (which always uses event.uuid).
          with {:has_event, {:ok, %Event{uuid: event_uuid}}} <-
                 {:has_event, Events.get_event_with_preload(event_id)} do
            context_id = Surveys.event_context_id(event_uuid)
            respondent_id = Surveys.actor_respondent_id(actor_id)

            case Surveys.check_gate(context_id, respondent_id) do
              {:ok, %{"required" => true, "survey_schema" => schema}} ->
                {:ok,
                 %{
                   status: :survey_required,
                   survey_schema: schema,
                   context_id: context_id,
                   participant: nil
                 }}

              {:ok, _} ->
                case do_actor_join_event(actor, event_id, args) do
                  {:ok, participant} ->
                    {:ok, %{status: :joined, survey_schema: nil, context_id: nil, participant: participant}}
                  error -> error
                end

              {:error, reason} ->
                {:error, reason}
            end
          else
            {:has_event, _} ->
              {:error, dgettext("errors", "Event not found")}
          end
        else
          case do_actor_join_event(actor, event_id, args) do
            {:ok, participant} ->
              {:ok, %{status: :joined, survey_schema: nil, context_id: nil, participant: participant}}
            error -> error
          end
        end

      _ ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}
    end
  end

  def actor_join_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id} = args,
        _resolution
      ) do
    with {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Mobilizon.Events.get_event_with_preload(event_id)},
         {:anonymous_participation_enabled, true} <-
           {:anonymous_participation_enabled,
            event.local == true && Config.anonymous_participation?() &&
              event.options.anonymous_participation == true},
         {:anonymous_actor_id, true} <-
           {:anonymous_actor_id, to_string(Config.anonymous_actor_id()) == actor_id},
         {:email_required, true} <-
           {:email_required,
            Config.anonymous_participation_email_required?() &&
              args |> Map.get(:email) |> valid_email?()},
         {:confirmation_token, {confirmation_token, role}} <-
           {:confirmation_token,
            if(Config.anonymous_participation_email_confirmation_required?(),
              do: {Crypto.random_string(30), :not_confirmed},
              else: {nil, :participant}
            )},
         # We only federate if the participation is not to be confirmed later
         args <-
           args
           |> Map.put(:confirmation_token, confirmation_token)
           |> Map.put(:cancellation_token, Crypto.random_string(30))
           |> Map.put(:role, role)
           |> Map.put(:local, role == :participant),
         {:actor_not_found, %Actor{} = actor} <-
           {:actor_not_found, Actors.get_actor_with_preload(actor_id)},
         {:ok, %Participant{} = participant} <- do_actor_join_event(actor, event_id, args) do
      if Config.anonymous_participation_email_required?() &&
           Config.anonymous_participation_email_confirmation_required?() do
        args
        |> Map.get(:email)
        |> Email.Participation.anonymous_participation_confirmation(
          participant,
          Map.get(args, :locale, "en")
        )
        |> Email.Mailer.send_email()
      end

      {:ok, %{status: :joined, survey_schema: nil, context_id: nil, participant: participant}}
    else
      {:error, err} ->
        {:error, err}

      {:has_event, _} ->
        {:error,
         dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}

      {:anonymous_participation_enabled, false} ->
        {:error, dgettext("errors", "Anonymous participation is not enabled")}

      {:anonymous_actor_id, false} ->
        {:error, dgettext("errors", "Profile ID provided is not the anonymous profile one")}

      {:email_required, _} ->
        {:error, dgettext("errors", "A valid email is required by your instance")}

      {:actor_not_found, _} ->
        Logger.error(
          "The actor ID \"#{actor_id}\" provided by configuration doesn't match any actor in database"
        )

        {:error, dgettext("errors", "Internal Error")}
    end
  end

  def actor_join_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to join an event")}
  end

  # Helper function to handle both regular and waitlist join results
  @spec handle_join_result(
          {:ok, any, Participant.t()}
          | {:ok, any, Participant.t(), :waitlist}
          | {:error, any}
        ) ::
          {:ok, Participant.t()} | {:error, any}
  defp handle_join_result({:ok, _activity, participant}), do: {:ok, participant}
  defp handle_join_result({:ok, _activity, participant, :waitlist}), do: {:ok, participant}
  defp handle_join_result({:error, reason}), do: {:error, reason}

  @spec do_actor_join_event(Actor.t(), integer | String.t(), map()) ::
          {:ok, Participant.t()} | {:error, String.t()}
  defp do_actor_join_event(actor, event_id, args) do
    with {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Events.get_event_with_preload(event_id)},
         join_result <- Participations.join(event, actor, args),
         {:ok, participant} <- handle_join_result(join_result),
         %Participant{} = participant <-
           participant
           |> Map.put(:event, event)
           |> Map.put(:actor, actor) do
      {:ok, participant}
    else
      {:error, :maximum_attendee_capacity_reached} ->
        {:error, dgettext("errors", "The event has already reached its maximum capacity")}

      {:has_event, _} ->
        {:error,
         dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}

      {:error, :event_not_found} ->
        {:error, dgettext("errors", "Event id not found")}

      {:error, :already_participant} ->
        {:error, dgettext("errors", "You are already a participant of this event")}
    end
  end

  @spec check_anonymous_participation(String.t(), String.t()) ::
          {:ok, Event.t()} | {:error, String.t()}
  defp check_anonymous_participation(actor_id, event_id) do
    cond do
      Config.anonymous_participation?() == false ->
        {:error, dgettext("errors", "Anonymous participation is not enabled")}

      to_string(Config.anonymous_actor_id()) != actor_id ->
        {:error, dgettext("errors", "The anonymous actor ID is invalid")}

      true ->
        case Mobilizon.Events.get_event_with_preload(event_id) do
          {:ok, %Event{} = event} ->
            {:ok, event}

          {:error, :event_not_found} ->
            {:error,
             dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}
        end
    end
  end

  @doc """
  Leave an event for an anonymous actor
  """
  @spec actor_leave_event(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def actor_leave_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id, token: token},
        _resolution
      )
      when not is_nil(token) do
    case check_anonymous_participation(actor_id, event_id) do
      {:ok, %Event{} = event} ->
        %Actor{} = actor = Actors.get_actor_with_preload!(actor_id)

        case Participations.leave(event, actor, %{local: false, cancellation_token: token}) do
          {:ok, _activity, %Participant{id: participant_id} = _participant} ->
            {:ok, %Event{} = event} = Events.get_event_with_preload(event_id)
            %Actor{} = actor = Actors.get_actor_with_preload!(actor_id)
            {:ok, %{event: event, actor: actor, id: participant_id}}

          {:error, :is_only_organizer} ->
            {:error,
             dgettext(
               "errors",
               "You can't leave event because you're the only event creator participant"
             )}

          {:error, :participant_not_found} ->
            {:error, dgettext("errors", "Participant not found")}

          {:error, _err} ->
            {:error, dgettext("errors", "Failed to leave the event")}
        end
    end
  end

  def actor_leave_event(
        _parent,
        %{actor_id: actor_id, event_id: event_id},
        %{context: %{current_user: user}}
      ) do
    with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         {:has_event, {:ok, %Event{} = event}} <-
           {:has_event, Events.get_event_with_preload(event_id)},
         {:ok, _activity, %Participant{id: participant_id} = _participant} <-
           Participations.leave(event, actor) do
      {:ok, %Event{} = event} = Events.get_event_with_preload(event_id)
      %Actor{} = actor = Actors.get_actor_with_preload!(actor_id)
      {:ok, %{event: event, actor: actor, id: participant_id}}
    else
      {:has_event, _} ->
        {:error, "Event with this ID #{inspect(event_id)} doesn't exist"}

      {:is_owned, nil} ->
        {:error, dgettext("errors", "Profile is not owned by authenticated user")}

      {:error, :is_only_organizer} ->
        {:error,
         dgettext(
           "errors",
           "You can't leave event because you're the only event creator participant"
         )}

      {:error, :participant_not_found} ->
        {:error, dgettext("errors", "Participant not found")}
    end
  end

  def actor_leave_event(_parent, _args, _resolution) do
    {:error, dgettext("errors", "You need to be logged-in to leave an event")}
  end

  @spec update_participation(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Participation.t()} | {:error, String.t() | Ecto.Changeset.t()}
  def update_participation(
        _parent,
        %{id: participation_id, role: new_role},
        %{
          context: %{
            current_actor: %Actor{} = moderator_actor
          }
        }
      ) do
    # Check that participation already exists

    case Events.get_participant(participation_id) do
      %Participant{role: old_role, event_id: event_id} = participation ->
        if new_role != old_role do
          %Event{} = event = Events.get_event_with_preload!(event_id)

          if can_event_be_updated_by?(event, moderator_actor) do
            with {:ok, _activity, participation} <-
                   Participations.update(participation, moderator_actor, new_role) do
              {:ok, participation}
            end
          else
            {:error,
             dgettext(
               "errors",
               "Provided profile doesn't have moderator permissions on this event"
             )}
          end
        else
          {:error, dgettext("errors", "Participant already has role %{role}", role: new_role)}
        end

      nil ->
        {:error, dgettext("errors", "Participant not found")}
    end
  end

  @spec confirm_participation_from_token(map(), map(), map()) ::
          {:ok, Participant.t()} | {:error, String.t()}
  def confirm_participation_from_token(
        _parent,
        %{confirmation_token: confirmation_token},
        _context
      ) do
    with {:has_participant,
          %Participant{actor: actor, role: :not_confirmed, event: event} = participant} <-
           {:has_participant, Events.get_participant_by_confirmation_token(confirmation_token)},
         {:ok, _activity, %Participant{} = participant} <-
           Participations.update(participant, actor, Events.get_default_participant_role(event)) do
      {:ok, participant}
    else
      {:has_participant, %Participant{role: :not_approved}} ->
        {:error,
         dgettext("errors", "Participation is confirmed but not approved yet by an organizer")}

      {:has_participant, %Participant{role: :participant}} ->
        {:error, dgettext("errors", "Participation is already confirmed")}

      {:has_participant, nil} ->
        {:error, dgettext("errors", "This token is invalid")}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec export_event_participants(any(), map(), Absinthe.Resolution.t()) :: {:ok, String.t()}
  def export_event_participants(_parent, %{event_id: event_id, roles: roles, format: format}, %{
        context: %{
          current_user: %User{locale: locale},
          current_actor: %Actor{} = moderator_actor
        }
      }) do
    case Events.get_event_with_preload(event_id) do
      {:ok, %Event{} = event} ->
        if can_event_be_updated_by?(event, moderator_actor) do
          case export_format(format, event, roles, locale) do
            {:ok, path} ->
              {:ok, %{path: path, format: format}}

            {:error, :export_dependency_not_installed} ->
              {:error,
               dgettext(
                 "errors",
                 "A dependency needed to export to %{format} is not installed",
                 format: format
               )}

            {:error, :failed_to_save_upload} ->
              {:error,
               dgettext(
                 "errors",
                 "An error occured while saving export",
                 format: format
               )}

            {:error, :format_not_supported} ->
              {:error,
               dgettext(
                 "errors",
                 "Format not supported"
               )}
          end
        else
          {:error,
           dgettext(
             "errors",
             "Provided profile doesn't have moderator permissions on this event"
           )}
        end

      {:error, :event_not_found} ->
        {:error,
         dgettext("errors", "Event with this ID %{id} doesn't exist", id: inspect(event_id))}
    end
  end

  def export_event_participants(_, _, _), do: {:error, :unauthorized}

  def send_private_messages_to_participants(
        _parent,
        %{roles: roles, event_id: event_id, actor_id: actor_id} =
          args,
        %{
          context: %{
            current_user: %User{locale: _locale},
            current_actor: %Actor{id: current_actor_id}
          }
        }
      ) do
    participant_actors =
      event_id
      |> Events.list_all_participants_for_event(roles)
      |> Enum.map(& &1.actor)

    mentions =
      participant_actors
      |> Enum.map(& &1.id)
      |> Enum.uniq()
      |> Enum.map(&%{actor_id: &1, event_id: event_id})

    args =
      Map.merge(args, %{
        mentions: mentions,
        visibility: :private
      })

    with {:ok,
          %Event{organizer_actor_id: organizer_actor_id, attributed_to_id: attributed_to_id} =
            _event} <- Mobilizon.Events.get_event(event_id),
         {:member, true} <-
           {:member,
            (to_string(current_actor_id) == to_string(organizer_actor_id) and
               to_string(current_actor_id) == to_string(actor_id)) or
              (!is_nil(attributed_to_id) and Actors.member?(current_actor_id, attributed_to_id) and
                 to_string(attributed_to_id) == to_string(actor_id))},
         {:ok, _activity, %Conversation{} = conversation} <- Comments.create_conversation(args) do
      {:ok, conversation_to_view(conversation, Actors.get_actor(actor_id))}
    else
      {:member, false} ->
        {:error, :unauthorized}

      {:error, :empty_participants} ->
        {:error,
         dgettext(
           "errors",
           "There are no participants matching the audience you've selected."
         )}

      {:error, err} ->
        {:error, err}
    end
  end

  def send_private_messages_to_participants(_parent, _args, _resolution),
    do: {:error, :unauthorized}

  defp conversation_to_view(
         %Conversation{id: conversation_id} = conversation,
         %Actor{id: actor_id} = actor
       ) do
    value =
      conversation
      |> Map.from_struct()
      |> Map.put(:actor, actor)
      |> Map.put(:unread, false)
      |> Map.put(
        :conversation_participant_id,
        Conversations.get_participant_by_conversation_and_actor(conversation_id, actor_id).id
      )

    struct(ConversationView, value)
  end

  @spec valid_email?(String.t() | nil) :: boolean
  defp valid_email?(email) when is_nil(email), do: false

  defp valid_email?(email) when is_binary(email) do
    email
    |> String.trim()
    |> Checker.valid?()
  end

  @doc """
  Submit a survey response
  """
  def submit_survey_response(
        _parent,
        %{context_id: context_id, data: data},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    respondent_id = Surveys.actor_respondent_id(actor_id)

    case Surveys.submit_response(context_id, respondent_id, data) do
      {:ok, _} -> {:ok, true}
      {:error, reason} -> {:error, reason}
    end
  end

  def submit_survey_response(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to submit a survey")}
  end

  @doc """
  Confirm joining an event after completing a survey
  """
  def confirm_event_join(
        _parent,
        %{event_id: event_id},
        %{context: %{current_user: %User{} = user, current_actor: %Actor{id: actor_id} = _actor}}
      ) do
    with {:has_event, {:ok, %Event{uuid: event_uuid}}} <-
           {:has_event, Events.get_event_with_preload(event_id)} do
      context_id = Surveys.event_context_id(event_uuid)
      respondent_id = Surveys.actor_respondent_id(actor_id)

      case Surveys.check_gate(context_id, respondent_id) do
        {:ok, %{"required" => false}} ->
          case User.owns_actor(user, actor_id) do
            {:is_owned, %Actor{} = owned_actor} ->
              case do_actor_join_event(owned_actor, event_id, %{actor_id: actor_id, event_id: event_id}) do
                {:ok, participant} ->
                  {:ok, %{status: :joined, survey_schema: nil, context_id: nil, participant: participant}}
                error -> error
              end
            _ ->
              {:error, dgettext("errors", "Profile is not owned by authenticated user")}
          end

        {:ok, %{"required" => true}} ->
          {:error, dgettext("errors", "Survey not completed")}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:has_event, _} ->
        {:error, dgettext("errors", "Event not found")}
    end
  end

  def confirm_event_join(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to confirm event join")}
  end

  @doc """
  Resolve the waitlist position for a participant.
  Returns the 1-based position in the waitlist, or nil if not on waitlist.
  """
  @spec resolve_waitlist_position(Participant.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, integer() | nil}
  def resolve_waitlist_position(
        %Participant{role: :waitlist, event_id: event_id, actor_id: actor_id},
        _args,
        _resolution
      ) do
    {:ok, Events.get_waitlist_position(event_id, actor_id)}
  end

  def resolve_waitlist_position(_participant, _args, _resolution) do
    {:ok, nil}
  end

  @spec export_format(atom(), Event.t(), list(), String.t()) ::
          {:ok, String.t()}
          | {:error,
             :format_not_supported | :export_dependency_not_installed | :failed_to_save_upload}
  defp export_format(format, event, roles, locale) do
    case format do
      :csv ->
        CSV.export(event, roles: roles, locale: locale)

      :pdf ->
        PDF.export(event, roles: roles, locale: locale)

      :ods ->
        ODS.export(event, roles: roles, locale: locale)

      _ ->
        {:error, :format_not_supported}
    end
  end

  @doc """
  Get a participant's survey response for an event (organizer-only)
  """
  def participant_survey_response(
        _parent,
        %{event_id: event_id, actor_id: actor_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:has_event, {:ok, %Event{uuid: event_uuid} = event}} <-
           {:has_event, Events.get_event_with_preload(event_id)},
         {:is_organizer, true} <-
           {:is_organizer, to_string(event.organizer_actor_id) == to_string(current_actor.id)} do
      context_id = Surveys.event_context_id(event_uuid)
      respondent_id = Surveys.actor_respondent_id(actor_id)

      case Surveys.get_participant_response(context_id, respondent_id) do
        {:ok, nil} -> {:ok, nil}
        {:ok, response} -> {:ok, response}
        {:error, reason} -> {:error, reason}
      end
    else
      {:has_event, _} -> {:error, dgettext("errors", "Event not found")}
      {:is_organizer, false} -> {:error, dgettext("errors", "You are not the organizer of this event")}
    end
  end

  def participant_survey_response(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to view survey responses")}
  end
end
