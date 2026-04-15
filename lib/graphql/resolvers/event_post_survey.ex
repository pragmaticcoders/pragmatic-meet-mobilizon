defmodule Mobilizon.GraphQL.Resolvers.EventPostSurvey do
  @moduledoc """
  Handles GraphQL calls for post-event surveys.
  All survey storage and lifecycle is delegated to the Adapter via the Surveys Behaviour.
  Mobilizon only handles authorization (using its own event/actor data) and
  respondent enrichment (mapping respondent_id back to Mobilizon actor info).
  """

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Plugins.Surveys

  import Mobilizon.Web.Gettext
  import Mobilizon.GraphQL.Resolvers.Event.Utils

  # ── Queries ───────────────────────────────────────────────────────────────────

  def list_event_post_surveys(_parent, %{event_id: event_id}, _resolution) do
    context_id = Surveys.event_survey_context_id(event_id)

    case Surveys.list_surveys(context_id) do
      {:ok, surveys} -> {:ok, Enum.map(surveys, &normalize_survey/1)}
      error -> error
    end
  end

  # ── Mutations ─────────────────────────────────────────────────────────────────

  def create_event_post_survey(
        _parent,
        %{event_id: event_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         context_id = Surveys.event_survey_context_id(event_id),
         {:ok, survey} <-
           Surveys.create_survey(context_id, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, normalize_survey(survey)}
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  def update_event_post_survey(
        _parent,
        %{event_id: event_id, survey_id: survey_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, survey} <-
           Surveys.update_survey(survey_id, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, normalize_survey(survey)}
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  def publish_event_post_survey(
        _parent,
        %{event_id: event_id, survey_id: survey_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, survey} <- Surveys.publish_survey(survey_id) do
      {:ok, normalize_survey(survey)}
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  def close_event_post_survey(
        _parent,
        %{event_id: event_id, survey_id: survey_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, survey} <- Surveys.close_survey(survey_id) do
      {:ok, normalize_survey(survey)}
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  # ── Responses (enriched with Mobilizon actor data) ────────────────────────────

  def list_survey_responses(
        _parent,
        %{event_id: event_id, survey_id: survey_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, responses} <- Surveys.get_survey_responses(survey_id),
         {:ok, survey} <- Surveys.get_survey(survey_id) do
      schema = Map.get(survey, "schema") || Map.get(survey, :schema) || %{}
      {:ok, enrich_responses(responses, schema)}
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_survey_responses(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to view survey responses")}
  end

  # ── Gate-check survey responses ───────────────────────────────────────────────

  def list_gate_check_survey_responses(
        _parent,
        %{event_id: event_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{uuid: event_uuid} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)} do
      context_id = Surveys.event_context_id(event_uuid)

      schema =
        case Surveys.list_surveys(context_id) do
          {:ok, [survey | _]} ->
            Map.get(survey, "schema") || Map.get(survey, :schema) || %{}

          _ ->
            %{}
        end

      case Surveys.get_responses(context_id) do
        {:ok, responses} -> {:ok, enrich_responses(responses, schema)}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_gate_check_survey_responses(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to view survey responses")}
  end

  # ── Private ───────────────────────────────────────────────────────────────────

  # Tesla's JSON middleware returns string-keyed maps. Absinthe's default resolver
  # tries the atom key first, then falls back to the string key. However, converting
  # to atom keys upfront guarantees reliable field resolution across all Absinthe
  # versions and avoids any edge cases with atom-not-found in the atom table.
  defp normalize_survey(survey) when is_map(survey) do
    %{
      id: Map.get(survey, :id, Map.get(survey, "id")),
      title: Map.get(survey, :title, Map.get(survey, "title")) || "",
      description: Map.get(survey, :description, Map.get(survey, "description")),
      schema: Map.get(survey, :schema, Map.get(survey, "schema")),
      status: Map.get(survey, :status, Map.get(survey, "status")),
      context_id: Map.get(survey, :context_id, Map.get(survey, "context_id"))
    }
  end

  defp normalize_survey(other), do: other

  defp enrich_responses(responses, schema) do
    Enum.map(responses, fn response ->
      {name, username, email} =
        response
        |> Map.get("respondent_id", "")
        |> extract_actor_id()
        |> lookup_actor_info()

      %{
        respondent_id: Map.get(response, "respondent_id"),
        respondent_name: name,
        respondent_username: username,
        respondent_email: email,
        submitted_at: Map.get(response, "created_at"),
        schema: schema,
        data: Map.get(response, "data")
      }
    end)
  end

  defp extract_actor_id("mobilizon_actor:" <> actor_id), do: actor_id
  defp extract_actor_id(_), do: nil

  defp lookup_actor_info(nil), do: {nil, nil, nil}

  defp lookup_actor_info(actor_id) do
    case Actors.get_actor_with_preload(actor_id) do
      %Actor{name: name, preferred_username: username, user: user} ->
        email = if user, do: user.email, else: nil
        {name || username, username, email}

      nil ->
        {nil, nil, nil}
    end
  end
end
