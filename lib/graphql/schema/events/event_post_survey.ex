defmodule Mobilizon.GraphQL.Schema.Events.EventPostSurveyType do
  @moduledoc """
  Schema representation for EventPostSurvey.
  """

  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.EventPostSurvey

  @desc "Represents a survey attached to an event (created post-publication)"
  object :event_post_survey do
    meta(:authorize, :all)
    field(:id, :id, description: "The survey ID")
    field(:uuid, :string, description: "Unique UUID used to identify the survey")
    field(:title, :string, description: "Survey title shown to participants")
    field(:description, :string, description: "Optional description shown above the form fields")
    field(:schema, :json, description: "Formio JSON schema")
    field(:status, :string, description: "Status: draft | published | closed")
    field(:context_id, :string, description: "Context ID used with the forms adapter")
    field(:event_id, :id, description: "ID of the parent event")
  end

  @desc "A single response to a post-event survey, enriched with respondent info"
  object :event_post_survey_response_item do
    meta(:authorize, :all)
    field(:respondent_id, :string, description: "Opaque respondent identifier")
    field(:respondent_name, :string, description: "Display name of the respondent")
    field(:respondent_username, :string, description: "Preferred username of the respondent")
    field(:respondent_email, :string, description: "Email of the respondent (nil for remote actors)")
    field(:submitted_at, :string, description: "ISO 8601 timestamp of submission")
    field(:schema, :json, description: "Survey schema (for rendering the response)")
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
      arg(:survey_id, non_null(:id), description: "The survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.list_survey_responses/3)
    end
  end

  object :event_post_survey_mutations do
    @desc "Create a new draft survey for an event"
    field :create_event_post_survey, :event_post_survey do
      arg(:event_id, non_null(:id), description: "The event ID")
      arg(:title, non_null(:string), description: "Survey title")
      arg(:description, :string, description: "Optional description shown above the form")
      arg(:schema, non_null(:json), description: "Formio JSON schema")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.create_event_post_survey/3)
    end

    @desc "Update the title/schema of a draft survey"
    field :update_event_post_survey, :event_post_survey do
      arg(:survey_id, non_null(:id), description: "The survey ID")
      arg(:title, non_null(:string), description: "Survey title")
      arg(:description, :string, description: "Optional description shown above the form")
      arg(:schema, non_null(:json), description: "Formio JSON schema")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.update_event_post_survey/3)
    end

    @desc "Publish a draft survey, making it visible to participants"
    field :publish_event_post_survey, :event_post_survey do
      arg(:survey_id, non_null(:id), description: "The survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.publish_event_post_survey/3)
    end

    @desc "Close a published survey, preventing further responses"
    field :close_event_post_survey, :event_post_survey do
      arg(:survey_id, non_null(:id), description: "The survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&EventPostSurvey.close_event_post_survey/3)
    end
  end
end
