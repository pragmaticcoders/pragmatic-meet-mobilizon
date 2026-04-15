defmodule Mobilizon.Service.Plugins.Surveys.NoopAdapterTest do
  use ExUnit.Case, async: true

  alias Mobilizon.Service.Plugins.Surveys.NoopAdapter

  describe "NoopAdapter" do
    test "enabled? returns false" do
      assert NoopAdapter.enabled?() == false
    end

    test "check_gate returns not required" do
      assert {:ok, %{"required" => false, "survey_schema" => nil}} =
               NoopAdapter.check_gate("event:1", "actor:1")
    end

    test "submit_response returns ok" do
      assert {:ok, %{}} = NoopAdapter.submit_response("event:1", "actor:1", %{})
    end

    test "save_survey returns ok" do
      assert {:ok, %{}} = NoopAdapter.save_survey("event:1", %{})
    end

    test "get_responses returns empty list" do
      assert {:ok, []} = NoopAdapter.get_responses("event:1")
    end
  end
end
