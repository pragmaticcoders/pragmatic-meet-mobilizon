defmodule Mobilizon.Service.Activity.SurveyTest do
  @moduledoc """
  Tests for the Survey activity module — verifies that publishing a survey
  enqueues the correct ActivityBuilder Oban job, and that nothing is enqueued
  when the survey plugin is disabled.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity.Survey, as: SurveyActivity
  alias Mobilizon.Service.Plugins.Surveys
  alias Mobilizon.Service.Workers.ActivityBuilder

  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory

  @survey %{
    "id" => "survey-ext-id-123",
    "title" => "Feedback survey",
    "description" => "Please give us your feedback.",
    "status" => "published"
  }

  # Temporarily enable the survey plugin for the duration of the test.
  defp enable_surveys do
    Config.put([Surveys, :adapter], Surveys.ExternalAdapter)
    on_exit(fn -> Config.put([Surveys, :adapter], Surveys.NoopAdapter) end)
  end

  describe "insert_event_survey_activity/3 when surveys are enabled" do
    setup do: enable_surveys()

    test "enqueues an ActivityBuilder job with the correct params when the event belongs to a group" do
      %Actor{id: group_id} = group = insert(:group)
      %Actor{id: actor_id} = actor = insert(:actor)

      %Event{uuid: event_uuid, title: event_title} =
        event = insert(:event, organizer_actor: actor, attributed_to: group)

      assert {:ok, _job} = SurveyActivity.insert_event_survey_activity(@survey, event, actor)

      assert_enqueued(
        worker: ActivityBuilder,
        args: %{
          "type" => "survey",
          "subject" => "survey_published",
          "subject_params" => %{
            "survey_title" => "Feedback survey",
            "survey_description" => "Please give us your feedback.",
            "survey_id" => "survey-ext-id-123",
            "event_uuid" => event_uuid,
            "event_title" => event_title,
            "context_type" => "event"
          },
          "group_id" => group_id,
          "author_id" => actor_id,
          "object_type" => "survey",
          "object_id" => nil,
          "op" => "build_activity"
        }
      )
    end

    test "returns {:ok, nil} and does NOT enqueue when the event has no group" do
      %Actor{} = actor = insert(:actor)

      %Event{} =
        event =
        insert(:event,
          organizer_actor: actor,
          attributed_to: nil,
          attributed_to_id: nil
        )

      assert {:ok, nil} = SurveyActivity.insert_event_survey_activity(@survey, event, actor)

      refute_enqueued(worker: ActivityBuilder, args: %{"type" => "survey"})
    end

    test "handles a survey with no description" do
      %Actor{} = group = insert(:group)
      %Actor{} = actor = insert(:actor)

      %Event{uuid: event_uuid} =
        event = insert(:event, organizer_actor: actor, attributed_to: group)

      survey_no_desc = %{"id" => "abc", "title" => "Quick poll"}

      assert {:ok, _} = SurveyActivity.insert_event_survey_activity(survey_no_desc, event, actor)

      assert_enqueued(
        worker: ActivityBuilder,
        args: %{
          "type" => "survey",
          "subject" => "survey_published",
          "subject_params" => %{
            "survey_title" => "Quick poll",
            "survey_description" => nil,
            "survey_id" => "abc",
            "event_uuid" => event_uuid,
            "context_type" => "event"
          }
        }
      )
    end
  end

  describe "insert_event_survey_activity/3 when surveys are disabled" do
    test "returns {:ok, nil} and does NOT enqueue, even for a grouped event" do
      %Actor{} = group = insert(:group)
      %Actor{} = actor = insert(:actor)

      %Event{} = event = insert(:event, organizer_actor: actor, attributed_to: group)

      assert {:ok, nil} = SurveyActivity.insert_event_survey_activity(@survey, event, actor)

      refute_enqueued(worker: ActivityBuilder, args: %{"type" => "survey"})
    end
  end

  describe "insert_group_survey_activity/3 when surveys are enabled" do
    setup do: enable_surveys()

    test "enqueues an ActivityBuilder job with the correct params" do
      %Actor{id: group_id} = group = insert(:group)
      %Actor{id: actor_id} = actor = insert(:actor)

      assert {:ok, _job} = SurveyActivity.insert_group_survey_activity(@survey, group, actor)

      assert_enqueued(
        worker: ActivityBuilder,
        args: %{
          "type" => "survey",
          "subject" => "survey_published",
          "subject_params" => %{
            "survey_title" => "Feedback survey",
            "survey_description" => "Please give us your feedback.",
            "survey_id" => "survey-ext-id-123",
            "context_type" => "group"
          },
          "group_id" => group_id,
          "author_id" => actor_id,
          "object_type" => "survey",
          "object_id" => nil,
          "op" => "build_activity"
        }
      )
    end

    test "handles a survey with no description" do
      %Actor{} = group = insert(:group)
      %Actor{} = actor = insert(:actor)

      survey_no_desc = %{id: "xyz", title: "Simple survey"}

      assert {:ok, _} = SurveyActivity.insert_group_survey_activity(survey_no_desc, group, actor)

      assert_enqueued(
        worker: ActivityBuilder,
        args: %{
          "type" => "survey",
          "subject" => "survey_published",
          "subject_params" => %{
            "survey_title" => "Simple survey",
            "survey_description" => nil,
            "context_type" => "group"
          }
        }
      )
    end
  end

  describe "insert_group_survey_activity/3 when surveys are disabled" do
    test "returns {:ok, nil} and does NOT enqueue" do
      %Actor{} = group = insert(:group)
      %Actor{} = actor = insert(:actor)

      assert {:ok, nil} = SurveyActivity.insert_group_survey_activity(@survey, group, actor)

      refute_enqueued(worker: ActivityBuilder, args: %{"type" => "survey"})
    end
  end
end
