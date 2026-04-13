defmodule Mobilizon.GraphQL.Resolvers.GroupPostSurvey do
  @moduledoc """
  Handles GraphQL calls for post-group surveys.
  All survey storage and lifecycle is delegated to the Adapter via the Surveys Behaviour.
  Mobilizon only handles authorization (using its own group/member data) and
  respondent enrichment (mapping respondent_id back to Mobilizon actor info).
  """

  alias Mobilizon.{Actors}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Service.Plugins.Surveys

  import Mobilizon.Web.Gettext

  @admin_roles [:moderator, :administrator, :creator]

  # ── Queries ───────────────────────────────────────────────────────────────────

  def list_group_post_surveys(_parent, %{group_id: group_id}, _resolution) do
    context_id = Surveys.group_survey_context_id(group_id)

    case Surveys.list_surveys(context_id) do
      {:ok, surveys} -> {:ok, Enum.map(surveys, &normalize_survey/1)}
      error -> error
    end
  end

  # ── Mutations ─────────────────────────────────────────────────────────────────

  def create_group_post_survey(
        _parent,
        %{group_id: group_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:authorized, true} <- {:authorized, admin?(actor_id, group_id)},
         context_id = Surveys.group_survey_context_id(group_id),
         {:ok, survey} <-
           Surveys.create_survey(context_id, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, normalize_survey(survey)}
    else
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, reason} -> {:error, reason}
    end
  end

  def update_group_post_survey(
        _parent,
        %{group_id: group_id, survey_id: survey_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:authorized, true} <- {:authorized, admin?(actor_id, group_id)},
         {:ok, survey} <-
           Surveys.update_survey(survey_id, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, normalize_survey(survey)}
    else
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, reason} -> {:error, reason}
    end
  end

  def publish_group_post_survey(
        _parent,
        %{group_id: group_id, survey_id: survey_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:authorized, true} <- {:authorized, admin?(actor_id, group_id)},
         {:ok, survey} <- Surveys.publish_survey(survey_id) do
      {:ok, normalize_survey(survey)}
    else
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, reason} -> {:error, reason}
    end
  end

  def close_group_post_survey(
        _parent,
        %{group_id: group_id, survey_id: survey_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:authorized, true} <- {:authorized, admin?(actor_id, group_id)},
         {:ok, survey} <- Surveys.close_survey(survey_id) do
      {:ok, normalize_survey(survey)}
    else
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, reason} -> {:error, reason}
    end
  end

  # ── Responses (enriched with Mobilizon actor data) ────────────────────────────

  def list_survey_responses(
        _parent,
        %{group_id: group_id, survey_id: survey_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:authorized, true} <- {:authorized, admin?(actor_id, group_id)},
         {:ok, responses} <- Surveys.get_survey_responses(survey_id),
         {:ok, survey} <- Surveys.get_survey(survey_id) do
      schema = Map.get(survey, "schema") || Map.get(survey, :schema) || %{}
      {:ok, enrich_responses(responses, schema)}
    else
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_survey_responses(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to view survey responses")}
  end

  # ── Private ───────────────────────────────────────────────────────────────────

  defp admin?(actor_id, group_id) do
    case Actors.get_member(actor_id, group_id) do
      {:ok, %Member{role: role}} -> role in @admin_roles
      _ -> false
    end
  end

  # Converts string-keyed maps returned by Tesla's JSON middleware to atom-keyed
  # maps, ensuring Absinthe resolves all fields reliably.
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

  defp enrich_responses(responses, schema \\ %{}) do
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
