defmodule Mobilizon.GraphQL.Schema.Actors.GroupPostSurveyType do
  @moduledoc """
  Schema representation for GroupPostSurvey (adapter-backed).
  """

  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.GroupPostSurvey

  @desc "Represents a survey attached to a group (managed by the survey adapter)"
  object :group_post_survey do
    meta(:authorize, :all)
    field(:id, :string, description: "Adapter-assigned survey ID")
    field(:title, :string, description: "Survey title shown to members")
    field(:description, :string, description: "Optional description shown above the form fields")
    field(:schema, :json, description: "Form builder JSON schema")
    field(:status, :string, description: "Status: draft | published | closed")
    field(:context_id, :string, description: "Context ID used with the forms adapter")
  end

  @desc "A single response to a group post-survey, enriched with respondent info"
  object :group_post_survey_response_item do
    meta(:authorize, :all)
    field(:respondent_id, :string, description: "Opaque respondent identifier")
    field(:respondent_name, :string, description: "Display name of the respondent")
    field(:respondent_username, :string, description: "Preferred username of the respondent")
    field(:respondent_email, :string, description: "Email of the respondent (nil for remote actors)")
    field(:submitted_at, :string, description: "ISO 8601 timestamp of submission")
    field(:schema, :json, description: "Survey schema — used client-side to resolve field labels")
    field(:data, :json, description: "Answer payload")
  end

  object :group_post_survey_queries do
    @desc "List surveys for a group"
    field :group_post_surveys, list_of(:group_post_survey) do
      arg(:group_id, non_null(:id), description: "The group actor ID")
      meta(:authorize, :all)
      middleware(Rajska.QueryAuthorization, permit: :all, scope: false)
      resolve(&GroupPostSurvey.list_group_post_surveys/3)
    end

    @desc "List responses for a specific group post-survey (admin only)"
    field :group_post_survey_responses, list_of(:group_post_survey_response_item) do
      arg(:group_id, non_null(:id), description: "The group ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&GroupPostSurvey.list_survey_responses/3)
    end
  end

  object :group_post_survey_mutations do
    @desc "Create a new draft survey for a group"
    field :create_group_post_survey, :group_post_survey do
      arg(:group_id, non_null(:id), description: "The group actor ID")
      arg(:title, non_null(:string), description: "Survey title")
      arg(:description, :string, description: "Optional description shown above the form")
      arg(:schema, non_null(:json), description: "Form builder JSON schema")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&GroupPostSurvey.create_group_post_survey/3)
    end

    @desc "Update the title/schema of a draft group survey"
    field :update_group_post_survey, :group_post_survey do
      arg(:group_id, non_null(:id), description: "The group ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      arg(:title, non_null(:string), description: "Survey title")
      arg(:description, :string, description: "Optional description shown above the form")
      arg(:schema, non_null(:json), description: "Form builder JSON schema")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&GroupPostSurvey.update_group_post_survey/3)
    end

    @desc "Publish a draft group survey, making it visible to members"
    field :publish_group_post_survey, :group_post_survey do
      arg(:group_id, non_null(:id), description: "The group ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&GroupPostSurvey.publish_group_post_survey/3)
    end

    @desc "Close a published group survey, preventing further responses"
    field :close_group_post_survey, :group_post_survey do
      arg(:group_id, non_null(:id), description: "The group ID (used for authorization)")
      arg(:survey_id, non_null(:string), description: "The adapter-assigned survey ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&GroupPostSurvey.close_group_post_survey/3)
    end
  end
end
