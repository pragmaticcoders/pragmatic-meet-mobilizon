defmodule Mobilizon.Service.Plugins.Surveys.SurveysTest do
  use ExUnit.Case, async: true

  alias Mobilizon.Service.Plugins.Surveys

  describe "helper functions" do
    test "event_context_id/1" do
      assert Surveys.event_context_id(42) == "mobilizon_event:42"
      assert Surveys.event_context_id("abc-123") == "mobilizon_event:abc-123"
    end

    test "group_context_id/1" do
      assert Surveys.group_context_id(7) == "mobilizon_group:7"
    end

    test "actor_respondent_id/1" do
      assert Surveys.actor_respondent_id(99) == "mobilizon_actor:99"
    end
  end
end
