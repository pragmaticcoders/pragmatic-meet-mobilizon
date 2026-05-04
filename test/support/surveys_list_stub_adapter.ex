defmodule Mobilizon.Test.SurveysListStubAdapter do
  @moduledoc false
  @behaviour Mobilizon.Service.Plugins.Surveys

  alias Mobilizon.Service.Plugins.Surveys.NoopAdapter

  @impl true
  def enabled?, do: NoopAdapter.enabled?()

  @impl true
  def check_gate(context_id, respondent_id),
    do: NoopAdapter.check_gate(context_id, respondent_id)

  @impl true
  def submit_response(context_id, respondent_id, data),
    do: NoopAdapter.submit_response(context_id, respondent_id, data)

  @impl true
  def submit_response(context_id, respondent_id, data, survey_id),
    do: NoopAdapter.submit_response(context_id, respondent_id, data, survey_id)

  @impl true
  def get_participant_response(context_id, respondent_id, survey_id),
    do: NoopAdapter.get_participant_response(context_id, respondent_id, survey_id)

  @impl true
  def list_surveys(context_id) do
    case Keyword.get(Application.get_env(:mobilizon, __MODULE__, []), :list_surveys) do
      nil -> NoopAdapter.list_surveys(context_id)
      fun when is_function(fun, 1) -> fun.(context_id)
    end
  end

  @impl true
  def get_survey(survey_id), do: NoopAdapter.get_survey(survey_id)

  @impl true
  def create_survey(context_id, attrs), do: NoopAdapter.create_survey(context_id, attrs)

  @impl true
  def update_survey(survey_id, attrs), do: NoopAdapter.update_survey(survey_id, attrs)

  @impl true
  def publish_survey(survey_id), do: NoopAdapter.publish_survey(survey_id)

  @impl true
  def close_survey(survey_id), do: NoopAdapter.close_survey(survey_id)

  @impl true
  def get_survey_responses(survey_id), do: NoopAdapter.get_survey_responses(survey_id)

  @impl true
  def save_survey(context_id, attrs), do: NoopAdapter.save_survey(context_id, attrs)

  @impl true
  def get_responses(context_id), do: NoopAdapter.get_responses(context_id)
end
