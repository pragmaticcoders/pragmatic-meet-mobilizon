defmodule Mobilizon.GraphQL.Schema.Events.EventPostSurveyType do
  @moduledoc """
  Schema representation for EventPostSurvey (adapter-backed).
  """

  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.EventPostSurvey

  @desc "Represents a survey attached to an event (managed by the survey adapter)"
  object :event_post_survey do
    meta(:authorize, :all)
    field(:id, :string, description: "Adapter-assigned survey ID")
    field(:title, :string, description: "Survey title shown to participants")
    field(:description, :string, description: "Optional description shown above the form fields")
    field(:schema, :json, description: "Form builder JSON schema")
    field(:status, :string, description: "Status: draft | published | closed")
    field(:context_id, :string, description: "Context ID used with the forms adapter")
  end

  @desc "A single response to a post-event survey, enriched with respondent info"
  object :event_post_survey_response_item do
    meta(:authorize, :all)
    field(:respondent_id, :string, description: "Opaque respondent identifier")
    field(:respondent_name, :string, description: "Display name of the respondent")
    field(:respondent_username, :string, description: "Preferred username of the respondent")
    field(:respondent_email, :string, description: "Email of the respondent (nil for remote actors)")
    field(:submitted_at, :string, description: "ISO 8601 timestamp of submission")
    field(:schema, :json, description: "Survey schema — used client-side to resolve field labels")
    field(:data, :json, description: "Answer payload")
  end

  object :event_post_survey_queries do
    @desc "List surveys for an event"
    field :event_post_surveys, list_of(:event_post_survey) do
      arg(:event_id, non_null(:id), description: "The event ID")
      meta(:authorize, :all)
      middleware(Rajska.QueryAuthorization, permit: :all, scope: false)
      resolve(&EventPostSurvey.list_event_post_surveys/3)
    end

    @desc "List responses for a specific post-event survey (admin only)"
    field :event_post_survey_responses, list_of(:event_post_survey_response_item) do
      arg(:event_id, non_null(:id), description: "The event ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.list_survey_responses/3)
    end

    @desc "List responses for the gate-check survey (filled before joining, admin only)"
    field :event_gate_check_survey_responses, list_of(:event_post_survey_response_item) do
      arg(:event_id, non_null(:id), description: "The event ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.list_gate_check_survey_responses/3)
    end
  end

  object :event_post_survey_mutations do
    @desc "Create a new draft survey for an event"
    field :create_event_post_survey, :event_post_survey do
      arg(:event_id, non_null(:id), description: "The event ID")
      arg(:title, non_null(:string), description: "Survey title")
      arg(:description, :string, description: "Optional description shown above the form")
      arg(:schema, non_null(:json), description: "Form builder JSON schema")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.create_event_post_survey/3)
    end

    @desc "Update the title/schema of a draft survey"
    field :update_event_post_survey, :event_post_survey do
      arg(:event_id, non_null(:id), description: "The event ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      arg(:title, non_null(:string), description: "Survey title")
      arg(:description, :string, description: "Optional description shown above the form")
      arg(:schema, non_null(:json), description: "Form builder JSON schema")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.update_event_post_survey/3)
    end

    @desc "Publish a draft survey, making it visible to participants"
    field :publish_event_post_survey, :event_post_survey do
      arg(:event_id, non_null(:id), description: "The event ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.publish_event_post_survey/3)
    end

    @desc "Close a published survey, preventing further responses"
    field :close_event_post_survey, :event_post_survey do
      arg(:event_id, non_null(:id), description: "The event ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.close_event_post_survey/3)
    end
  end
end
