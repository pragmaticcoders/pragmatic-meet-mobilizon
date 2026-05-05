defmodule Mobilizon.Service.Activity.Survey do
  @moduledoc """
  Insert a survey activity when a survey is published to an event or a group.
  No-ops when the survey plugin is disabled.

  Event surveys are dispatched through `LegacyNotifierBuilder` so that **event
  participants** (registered + anonymous) get notified directly — independently
  of whether the event is attributed to a group or who its group members are.

  Group surveys still go through `ActivityBuilder` so they land in the group's
  activity feed and are delivered to all group members (with the usual
  recap/direct delivery rules).
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Plugins.Surveys
  alias Mobilizon.Service.Workers.{ActivityBuilder, LegacyNotifierBuilder}

  @spec insert_event_survey_activity(map(), Event.t(), Actor.t()) ::
          {:ok, Oban.Job.t()} | {:ok, nil} | {:error, any()}
  def insert_event_survey_activity(
        survey,
        %Event{} = event,
        %Actor{id: current_actor_id}
      ) do
    if Surveys.enabled?() do
      LegacyNotifierBuilder.enqueue(:legacy_notify, %{
        "type" => "survey",
        "subject" => "survey_published",
        "subject_params" => %{
          survey_title: survey_title(survey),
          survey_description: survey_description(survey),
          survey_id: survey_id(survey),
          event_id: event.id,
          event_uuid: event.uuid,
          event_title: event.title,
          context_type: "event"
        },
        "author_id" => current_actor_id,
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
