defmodule Mobilizon.GraphQL.Resolvers.GroupPostSurvey do
  @moduledoc """
  Handles GraphQL calls for post-event surveys attached to groups.
  """

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.{Actor, GroupPostSurvey, Member}
  alias Mobilizon.Service.Plugins.Surveys

  import Mobilizon.Web.Gettext

  @member_roles [:member, :moderator, :administrator, :creator]

  # ── Queries ───────────────────────────────────────────────────────────────────

  @doc """
  Lists surveys for a group. Admins see all statuses; members see
  published+closed; non-members see nothing.
  """
  def list_group_post_surveys(
        _parent,
        %{group_id: group_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    surveys = Actors.list_group_post_surveys(group_id)

    cond do
      Actors.administrator?(actor_id, group_id) ->
        {:ok, surveys}

      is_member?(actor_id, group_id) ->
        {:ok, Enum.filter(surveys, &(&1.status in ["published", "closed"]))}

      true ->
        {:ok, []}
    end
  end

  def list_group_post_surveys(_parent, %{group_id: group_id}, _resolution) do
    surveys = Actors.list_group_post_surveys(group_id)
    {:ok, Enum.filter(surveys, &(&1.status in ["published", "closed"]))}
  end

  @doc "Lists all responses for a group survey, enriched with respondent actor info."
  def list_survey_responses(
        _parent,
        %{survey_id: survey_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:ok, %GroupPostSurvey{} = survey} <- Actors.get_group_post_survey(survey_id),
         {:authorized, true} <- {:authorized, Actors.administrator?(actor_id, survey.group_id)},
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
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_survey_responses(_, _, _) do
    {:error, dgettext("errors", "You need to be logged-in to view survey responses")}
  end

  # ── Mutations ─────────────────────────────────────────────────────────────────

  @doc "Creates a new draft survey for a group."
  def create_group_post_survey(
        _parent,
        %{group_id: group_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:authorized, true} <- {:authorized, Actors.administrator?(actor_id, group_id)},
         {:ok, %GroupPostSurvey{} = survey} <-
           Actors.create_group_post_survey(group_id, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, survey}
    else
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Updates a draft group survey's title and schema."
  def update_group_post_survey(
        _parent,
        %{survey_id: survey_id, title: title, schema: schema} = args,
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:ok, %GroupPostSurvey{} = survey} <- Actors.get_group_post_survey(survey_id),
         {:authorized, true} <- {:authorized, Actors.administrator?(actor_id, survey.group_id)},
         {:ok, %GroupPostSurvey{} = updated} <-
           Actors.update_group_post_survey(survey, %{
             title: title,
             description: Map.get(args, :description),
             schema: schema
           }) do
      {:ok, updated}
    else
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, :not_draft} ->
        {:error, dgettext("errors", "Only draft surveys can be edited")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Publishes a draft group survey, making it visible to members."
  def publish_group_post_survey(
        _parent,
        %{survey_id: survey_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:ok, %GroupPostSurvey{status: "draft"} = survey} <-
           Actors.get_group_post_survey(survey_id),
         {:authorized, true} <- {:authorized, Actors.administrator?(actor_id, survey.group_id)},
         :ok <- maybe_sync_survey_to_adapter(survey),
         {:ok, %GroupPostSurvey{} = updated} <-
           Actors.update_group_post_survey_status(survey, "published") do
      {:ok, updated}
    else
      {:ok, %GroupPostSurvey{status: status}} ->
        {:error,
         dgettext("errors", "Only draft surveys can be published (current status: %{status})",
           status: status
         )}
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Closes a published group survey, preventing further responses."
  def close_group_post_survey(
        _parent,
        %{survey_id: survey_id},
        %{context: %{current_actor: %Actor{id: actor_id}}}
      ) do
    with {:ok, %GroupPostSurvey{status: "published"} = survey} <-
           Actors.get_group_post_survey(survey_id),
         {:authorized, true} <- {:authorized, Actors.administrator?(actor_id, survey.group_id)},
         {:ok, %GroupPostSurvey{} = updated} <-
           Actors.update_group_post_survey_status(survey, "closed") do
      {:ok, updated}
    else
      {:ok, %GroupPostSurvey{status: status}} ->
        {:error,
         dgettext("errors", "Only published surveys can be closed (current status: %{status})",
           status: status
         )}
      {:error, :not_found} -> {:error, dgettext("errors", "Survey not found")}
      {:authorized, false} ->
        {:error, dgettext("errors", "You are not allowed to manage surveys for this group")}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # ── Private ───────────────────────────────────────────────────────────────────

  defp is_member?(actor_id, group_id) do
    case Actors.get_member(actor_id, group_id) do
      {:ok, %Member{role: role}} -> role in @member_roles
      _ -> false
    end
  end

  defp maybe_sync_survey_to_adapter(%GroupPostSurvey{context_id: context_id, schema: schema}) do
    if Surveys.enabled?() do
      case Surveys.save_survey(context_id, schema) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
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
