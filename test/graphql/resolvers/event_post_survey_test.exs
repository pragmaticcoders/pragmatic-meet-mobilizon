defmodule Mobilizon.GraphQL.Resolvers.EventPostSurveyTest do
  use Mobilizon.Web.ConnCase, async: false

  import Mobilizon.Factory

  alias Mobilizon.Config
  alias Mobilizon.GraphQL.AbsintheHelpers
  alias Mobilizon.Service.Plugins.Surveys

  @gate_check_survey_query """
  query EventGateCheckSurvey($eventId: ID!) {
    eventGateCheckSurvey(eventId: $eventId) {
      id
      title
      status
    }
  }
  """

  setup %{conn: conn} do
    previous_surveys = Application.get_env(:mobilizon, Surveys)
    Config.put([Surveys, :adapter], Mobilizon.Test.SurveysListStubAdapter)

    on_exit(fn ->
      case previous_surveys do
        nil -> Application.delete_env(:mobilizon, Surveys)
        cfg -> Application.put_env(:mobilizon, Surveys, cfg)
      end

      Application.delete_env(:mobilizon, Mobilizon.Test.SurveysListStubAdapter)
    end)

    {:ok, conn: conn}
  end

  describe "eventGateCheckSurvey" do
    test "returns null when the adapter lists no gate-check survey", %{conn: conn} do
      event = insert(:event)

      Application.put_env(:mobilizon, Mobilizon.Test.SurveysListStubAdapter,
        list_surveys: fn _ctx -> {:ok, []} end
      )

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @gate_check_survey_query,
          variables: %{eventId: to_string(event.id)}
        )

      assert res["errors"] == nil
      assert res["data"]["eventGateCheckSurvey"] == nil
    end

    test "returns the first survey when the adapter returns one", %{conn: conn} do
      event = insert(:event)
      expected_ctx = Surveys.event_context_id(event.uuid)

      Application.put_env(:mobilizon, Mobilizon.Test.SurveysListStubAdapter,
        list_surveys: fn ctx ->
          assert ctx == expected_ctx

          {:ok,
           [
             %{
               "id" => "gate-survey-1",
               "title" => "Pre-event form",
               "status" => "published",
               "schema" => %{}
             }
           ]}
        end
      )

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @gate_check_survey_query,
          variables: %{eventId: to_string(event.id)}
        )

      assert res["errors"] == nil
      survey = res["data"]["eventGateCheckSurvey"]
      assert survey["id"] == "gate-survey-1"
      assert survey["title"] == "Pre-event form"
      assert survey["status"] == "published"
    end

    test "returns an error when the event does not exist", %{conn: conn} do
      Application.put_env(:mobilizon, Mobilizon.Test.SurveysListStubAdapter,
        list_surveys: fn _ -> flunk("list_surveys must not be called for missing events") end
      )

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @gate_check_survey_query,
          variables: %{eventId: "999999999"}
        )

      assert [%{"message" => "Event not found"}] = res["errors"]
    end

    test "surfaces adapter errors from list_surveys", %{conn: conn} do
      event = insert(:event)

      Application.put_env(:mobilizon, Mobilizon.Test.SurveysListStubAdapter,
        list_surveys: fn _ctx -> {:error, "Survey list failed: upstream"} end
      )

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @gate_check_survey_query,
          variables: %{eventId: to_string(event.id)}
        )

      assert [%{"message" => msg}] = res["errors"]
      assert msg =~ "Survey list failed"
    end
  end
end
