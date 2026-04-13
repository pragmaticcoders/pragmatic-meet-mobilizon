defmodule Mobilizon.Service.Plugins.Surveys.NoopAdapter do
  @moduledoc """
  Noop adapter for the survey plugin. Used when the survey plugin is disabled.
  """
  @behaviour Mobilizon.Service.Plugins.Surveys

  @impl true
  def enabled?, do: false

  @impl true
  def check_gate(_context_id, _respondent_id) do
    {:ok, %{"required" => false, "survey_schema" => nil}}
  end

  @impl true
  def submit_response(_context_id, _respondent_id, _data) do
    {:ok, %{}}
  end

  @impl true
  def get_participant_response(_context_id, _respondent_id) do
    {:ok, nil}
  end

  @impl true
  def list_surveys(_context_id), do: {:ok, []}

  @impl true
  def get_survey(_survey_id), do: {:ok, %{}}

  @impl true
  def create_survey(_context_id, _attrs), do: {:error, :plugin_disabled}

  @impl true
  def update_survey(_survey_id, _attrs), do: {:error, :plugin_disabled}

  @impl true
  def publish_survey(_survey_id), do: {:error, :plugin_disabled}

  @impl true
  def close_survey(_survey_id), do: {:error, :plugin_disabled}

  @impl true
  def get_survey_responses(_survey_id), do: {:ok, []}

  @impl true
  def save_survey(_context_id, _schema), do: {:ok, %{}}

  @impl true
  def get_responses(_context_id), do: {:ok, []}
end
