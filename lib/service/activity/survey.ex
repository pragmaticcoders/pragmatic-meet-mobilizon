defmodule Mobilizon.Service.Activity.Survey do
  @moduledoc """
  Insert a survey activity when a survey is published to an event or a group.
  No-ops when the survey plugin is disabled.
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Plugins.Surveys
  alias Mobilizon.Service.Workers.ActivityBuilder

  @spec insert_event_survey_activity(map(), Event.t(), Actor.t()) ::
          {:ok, Oban.Job.t()} | {:ok, nil} | {:error, any()}
  def insert_event_survey_activity(
        survey,
        %Event{attributed_to_id: attributed_to_id, organizer_actor_id: organizer_actor_id} =
          event,
        %Actor{} = _current_actor
      )
      when not is_nil(attributed_to_id) do
    if Surveys.enabled?() do
      actor = Actors.get_actor(organizer_actor_id)
      group = Actors.get_actor(attributed_to_id)

      ActivityBuilder.enqueue(:build_activity, %{
        "type" => "survey",
        "subject" => "survey_published",
        "subject_params" => %{
          survey_title: survey_title(survey),
          survey_description: survey_description(survey),
          survey_id: survey_id(survey),
          event_uuid: event.uuid,
          event_title: event.title,
          context_type: "event"
        },
        "group_id" => group.id,
        "author_id" => actor.id,
        "object_type" => "survey",
        "object_id" => nil,
        "inserted_at" => DateTime.utc_now()
      })
    else
      {:ok, nil}
    end
  end

  def insert_event_survey_activity(_, _, _), do: {:ok, nil}

  @spec insert_group_survey_activity(map(), Actor.t(), Actor.t()) ::
          {:ok, Oban.Job.t()} | {:ok, nil} | {:error, any()}
  def insert_group_survey_activity(survey, %Actor{} = group, %Actor{} = current_actor) do
    if Surveys.enabled?() do
      ActivityBuilder.enqueue(:build_activity, %{
        "type" => "survey",
        "subject" => "survey_published",
        "subject_params" => %{
          survey_title: survey_title(survey),
          survey_description: survey_description(survey),
          survey_id: survey_id(survey),
          context_type: "group"
        },
        "group_id" => group.id,
        "author_id" => current_actor.id,
        "object_type" => "survey",
        "object_id" => nil,
        "inserted_at" => DateTime.utc_now()
      })
    else
      {:ok, nil}
    end
  end

  defp survey_title(survey), do: Map.get(survey, :title, Map.get(survey, "title")) || ""

  defp survey_description(survey),
    do: Map.get(survey, :description, Map.get(survey, "description"))

  defp survey_id(survey), do: Map.get(survey, :id, Map.get(survey, "id"))
end
