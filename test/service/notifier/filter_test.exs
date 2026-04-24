defmodule Mobilizon.Service.Notifier.FilterTest do
  @moduledoc """
  Tests for the Filter module — verifies that activities are correctly mapped to
  their activity-setting keys and gated by user preferences.
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Service.Notifier.Filter
  alias Mobilizon.Users.{ActivitySetting, User}

  use Mobilizon.DataCase
  import Mobilizon.Factory

  defp default_false(_key), do: false
  defp default_true(_key), do: true

  describe "can_send_activity?/4 for survey_published" do
    test "returns false by default (no activity setting row, default returns false)" do
      %Activity{} =
        activity =
        insert(:mobilizon_activity,
          type: :survey,
          subject: :survey_published,
          subject_params: %{"context_type" => "group", "survey_title" => "Test"}
        )

      %User{} = user = insert(:user, activity_settings: [])

      refute Filter.can_send_activity?(activity, "email", user, &default_false/1)
      refute Filter.can_send_activity?(activity, "push", user, &default_false/1)
    end

    test "returns true when default function returns true and no override row exists" do
      %Activity{} =
        activity =
        insert(:mobilizon_activity,
          type: :survey,
          subject: :survey_published,
          subject_params: %{"context_type" => "event", "survey_title" => "Test"}
        )

      %User{} = user = insert(:user, activity_settings: [])

      assert Filter.can_send_activity?(activity, "email", user, &default_true/1)
      assert Filter.can_send_activity?(activity, "push", user, &default_true/1)
    end

    test "respects an explicit enabled=true user activity setting for email" do
      %Activity{} =
        activity =
        insert(:mobilizon_activity,
          type: :survey,
          subject: :survey_published,
          subject_params: %{"context_type" => "group", "survey_title" => "Test"}
        )

      %User{} = user = insert(:user)

      %ActivitySetting{} =
        setting =
        insert(:mobilizon_activity_setting,
          user_id: user.id,
          user: user,
          key: "survey_published",
          method: "email",
          enabled: true
        )

      user = %User{user | activity_settings: [setting]}

      assert Filter.can_send_activity?(activity, "email", user, &default_false/1)
    end

    test "respects an explicit enabled=false user activity setting for push" do
      %Activity{} =
        activity =
        insert(:mobilizon_activity,
          type: :survey,
          subject: :survey_published,
          subject_params: %{"context_type" => "group", "survey_title" => "Test"}
        )

      %User{} = user = insert(:user)

      %ActivitySetting{} =
        setting =
        insert(:mobilizon_activity_setting,
          user_id: user.id,
          user: user,
          key: "survey_published",
          method: "push",
          enabled: false
        )

      user = %User{user | activity_settings: [setting]}

      refute Filter.can_send_activity?(activity, "push", user, &default_true/1)
    end

    test "a push setting does not affect email filtering" do
      %Activity{} =
        activity =
        insert(:mobilizon_activity,
          type: :survey,
          subject: :survey_published,
          subject_params: %{"context_type" => "event", "survey_title" => "Test"}
        )

      %User{} = user = insert(:user)

      %ActivitySetting{} =
        push_setting =
        insert(:mobilizon_activity_setting,
          user_id: user.id,
          user: user,
          key: "survey_published",
          method: "push",
          enabled: true
        )

      user = %User{user | activity_settings: [push_setting]}

      # No email setting exists → falls back to default_false
      refute Filter.can_send_activity?(activity, "email", user, &default_false/1)
      # Push setting is enabled
      assert Filter.can_send_activity?(activity, "push", user, &default_false/1)
    end
  end
end
