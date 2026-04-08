defmodule Mobilizon.GraphQL.Resolvers.EventPostSurvey do
  @moduledoc """
  Handles GraphQL calls for post-event surveys.
  """

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, EventPostSurvey}
  alias Mobilizon.Service.Plugins.Surveys

  import Mobilizon.Web.Gettext
  import Mobilizon.GraphQL.Resolvers.Event.Utils

  # ── Queries ───────────────────────────────────────────────────────────────────

  @doc """
  Lists surveys for an event. Admins see all statuses; others see only
  published and closed surveys.
  """
  def list_event_post_surveys(
        _parent,
        %{event_id: event_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    surveys = Events.list_event_post_surveys(event_id)

    case Events.get_event_with_preload(event_id) do
      {:ok, %Event{} = event} ->
        if can_manage_event_surveys?(event, current_actor) do
          {:ok, surveys}
        else
          {:ok, Enum.filter(surveys, &(&1.status in ["published", "closed"]))}
        end

      _ ->
        {:ok, Enum.filter(surveys, &(&1.status in ["published", "closed"]))}
    end
  end

  def list_event_post_surveys(_parent, %{event_id: event_id}, _resolution) do
    surveys = Events.list_event_post_surveys(event_id)
    {:ok, Enum.filter(surveys, &(&1.status in ["published", "closed"]))}
  end

  # ── Mutations ─────────────────────────────────────────────────────────────────

  @doc "Creates a new draft survey for an event."
  def create_event_post_survey(
        _parent,
        %{event_id: event_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, %EventPostSurvey{} = survey} <-
           Events.create_event_post_survey(event_id, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, survey}
    else
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Updates a draft survey's title and schema."
  def update_event_post_survey(
        _parent,
        %{survey_id: survey_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %EventPostSurvey{} = survey} <- Events.get_event_post_survey(survey_id),
         {:ok, %Event{} = event} <- Events.get_event_with_preload(survey.event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, %EventPostSurvey{} = updated} <-
           Events.update_event_post_survey(survey, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, updated}
    else
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, :not_draft} ->
        {:error, dgettext("errors", "Only draft surveys can be edited")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Publishes a draft survey, making it visible to participants."
  def publish_event_post_survey(
        _parent,
        %{survey_id: survey_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %EventPostSurvey{status: "draft"} = survey} <-
           Events.get_event_post_survey(survey_id),
         {:ok, %Event{} = event} <- Events.get_event_with_preload(survey.event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         :ok <- maybe_sync_survey_to_adapter(survey),
         {:ok, %EventPostSurvey{} = updated} <-
           Events.update_event_post_survey_status(survey, "published") do
      {:ok, updated}
    else
      {:ok, %EventPostSurvey{status: status}} ->
        {:error,
         dgettext("errors", "Only draft surveys can be published (current status: %{status})",
           status: status
         )}
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Closes a published survey, preventing further responses."
  def close_event_post_survey(
        _parent,
        %{survey_id: survey_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %EventPostSurvey{status: "published"} = survey} <-
           Events.get_event_post_survey(survey_id),
         {:ok, %Event{} = event} <- Events.get_event_with_preload(survey.event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, %EventPostSurvey{} = updated} <-
           Events.update_event_post_survey_status(survey, "closed") do
      {:ok, updated}
    else
      {:ok, %EventPostSurvey{status: status}} ->
        {:error,
         dgettext("errors", "Only published surveys can be closed (current status: %{status})",
           status: status
         )}
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # ── Private ───────────────────────────────────────────────────────────────────

  defp maybe_sync_survey_to_adapter(%EventPostSurvey{context_id: context_id, schema: schema}) do
    if Surveys.enabled?() do
      case Surveys.save_survey(context_id, schema) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
  end

  @doc "Lists all responses for a post-event survey, enriched with respondent actor info."
  def list_survey_responses(
        _parent,
        %{survey_id: survey_id},
        %{context: %{current_actor: %Actor{} = current_actor}}
      ) do
    with {:ok, %EventPostSurvey{} = survey} <- Events.get_event_post_survey(survey_id),
         {:ok, %Event{} = event} <- Events.get_event_with_preload(survey.event_id),
         {:authorized, true} <- {:authorized, can_manage_event_surveys?(event, current_actor)},
         {:ok, responses} <- Surveys.get_responses(survey.context_id) do
      enriched =
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
            schema: survey.schema,
            data: Map.get(response, "data")
          }
        end)

      {:ok, enriched}
    else
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:error, :event_not_found} -> {:error, dgettext("errors", "Event not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this event")}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_survey_responses(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to view survey responses")}
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
