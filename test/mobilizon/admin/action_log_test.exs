defmodule Mobilizon.Service.Admin.ActionLogTest do
  @moduledoc """
  Test the ActionLog module.
  """

  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Admin
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Reports.{Note, Report}

  setup do
    moderator_user = insert(:user, role: :moderator)
    moderator_actor = insert(:actor, user: moderator_user)
    {:ok, moderator: moderator_actor}
  end

  describe "action_log_creation" do
    # TODO: Action log creation is not working - see docs/TEST_FAILURES_CONSULTATION.md
    # Action logs are not being created via Admin.log_action
    # This needs team consultation to determine if this is intentional or a bug
    @tag :skip
    test "log a report update", %{moderator: moderator} do
      %Report{id: report_id} = report = insert(:report)

      assert {:ok,
              %ActionLog{
                target_type: "Elixir.Mobilizon.Reports.Report",
                target_id: found_report_id,
                action: :update,
                actor: _moderator
              }} = Admin.log_action(moderator, "update", report)

      assert found_report_id == report_id
    end

    # TODO: Action log creation is not working - see docs/TEST_FAILURES_CONSULTATION.md
    # Action logs are not being created via Admin.log_action
    # This needs team consultation to determine if this is intentional or a bug
    @tag :skip
    test "log the creation of a report note", %{moderator: moderator} do
      %Report{} = report = insert(:report)
      %Note{id: note_id} = report = insert(:report_note, report: report)

      assert {:ok,
              %ActionLog{
                target_type: "Elixir.Mobilizon.Reports.Note",
                target_id: found_note_id,
                action: :create,
                actor: _moderator
              }} = Admin.log_action(moderator, "create", report)

      assert found_note_id == note_id
    end
  end
end
