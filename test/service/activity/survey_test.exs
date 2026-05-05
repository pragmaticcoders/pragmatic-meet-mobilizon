defmodule Mobilizon.Service.Activity.SurveyTest do
  @moduledoc """
  Tests for the Survey activity module.

  - Event surveys go through `LegacyNotifierBuilder` so that *event participants*
    (registered + anonymous) are notified directly, regardless of whether the
    event is attributed to a group.
  - Group surveys still go through `ActivityBuilder` so they land in the group
    activity feed and notify all group members.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity.Survey, as: SurveyActivity
  alias Mobilizon.Service.Plugins.Surveys
  alias Mobilizon.Service.Workers.{ActivityBuilder, LegacyNotifierBuilder}

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

    test "enqueues a LegacyNotifierBuilder job for an event attributed to a group" do
      %Actor{} = group = insert(:group)
      %Actor{id: actor_id} = actor = insert(:actor)

      %Event{id: event_id, uuid: event_uuid, title: event_title} =
        event = insert(:event, organizer_actor: actor, attributed_to: group)

      assert {:ok, _job} = SurveyActivity.insert_event_survey_activity(@survey, event, actor)

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "type" => "survey",
          "subject" => "survey_published",
          "subject_params" => %{
            "survey_title" => "Feedback survey",
            "survey_description" => "Please give us your feedback.",
            "survey_id" => "survey-ext-id-123",
            "event_id" => event_id,
            "event_uuid" => event_uuid,
            "event_title" => event_title,
            "context_type" => "event"
          },
          "author_id" => actor_id,
          "object_type" => "survey",
          "object_id" => nil,
          "op" => "legacy_notify"
        }
      )

      # We deliberately do NOT enqueue an ActivityBuilder job — event surveys
      # are direct notifications to participants, not group-feed activities.
      refute_enqueued(worker: ActivityBuilder, args: %{"type" => "survey"})
    end

    test "enqueues a LegacyNotifierBuilder job even for an event without a group" do
      %Actor{id: actor_id} = actor = insert(:actor)

      %Event{id: event_id, uuid: event_uuid} =
        event =
        insert(:event,
          organizer_actor: actor,
          attributed_to: nil,
          attributed_to_id: nil
        )

      assert {:ok, _job} = SurveyActivity.insert_event_survey_activity(@survey, event, actor)

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "type" => "survey",
          "subject" => "survey_published",
          "subject_params" => %{
            "survey_title" => "Feedback survey",
            "survey_description" => "Please give us your feedback.",
            "survey_id" => "survey-ext-id-123",
            "event_id" => event_id,
            "event_uuid" => event_uuid,
            "context_type" => "event"
          },
          "author_id" => actor_id,
          "op" => "legacy_notify"
        }
      )
    end

    test "handles a survey with no description" do
      %Actor{} = group = insert(:group)
      %Actor{} = actor = insert(:actor)

      %Event{uuid: event_uuid} =
        event = insert(:event, organizer_actor: actor, attributed_to: group)

      survey_no_desc = %{"id" => "abc", "title" => "Quick poll"}

      assert {:ok, _} = SurveyActivity.insert_event_survey_activity(survey_no_desc, event, actor)

      assert_enqueued(
        worker: LegacyNotifierBuilder,
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

      refute_enqueued(worker: LegacyNotifierBuilder, args: %{"type" => "survey"})
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
