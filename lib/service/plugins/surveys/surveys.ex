defmodule Mobilizon.Service.Plugins.Surveys do
  @moduledoc """
  Survey plugin behaviour and dispatcher.
  Follows the pattern from Mobilizon.Service.Geospatial.Provider.
  """

  @type context_id :: String.t()
  @type respondent_id :: String.t()

  @callback enabled?() :: boolean()
  @callback check_gate(context_id(), respondent_id()) :: {:ok, map()} | {:error, any()}
  @callback submit_response(context_id(), respondent_id(), map()) :: {:ok, map()} | {:error, any()}
  @callback save_survey(context_id(), map()) :: {:ok, map()} | {:error, any()}
  @callback get_responses(context_id()) :: {:ok, list(map())} | {:error, any()}
  @callback get_participant_response(context_id(), respondent_id()) :: {:ok, map() | nil} | {:error, any()}

  @spec adapter() :: module()
  defp adapter do
    config()[:adapter] || __MODULE__.NoopAdapter
  end

  @spec config() :: keyword()
  defp config do
    Application.get_env(:mobilizon, __MODULE__, [])
  end

  @spec enabled?() :: boolean()
  def enabled? do
    adapter().enabled?()
  end

  @spec check_gate(context_id(), respondent_id()) :: {:ok, map()} | {:error, any()}
  def check_gate(context_id, respondent_id) do
    adapter().check_gate(context_id, respondent_id)
  end

  @spec submit_response(context_id(), respondent_id(), map()) :: {:ok, map()} | {:error, any()}
  def submit_response(context_id, respondent_id, data) do
    adapter().submit_response(context_id, respondent_id, data)
  end

  @spec save_survey(context_id(), map()) :: {:ok, map()} | {:error, any()}
  def save_survey(context_id, schema) do
    adapter().save_survey(context_id, schema)
  end

  @spec get_responses(context_id()) :: {:ok, list(map())} | {:error, any()}
  def get_responses(context_id) do
    adapter().get_responses(context_id)
  end

  @spec get_participant_response(context_id(), respondent_id()) :: {:ok, map() | nil} | {:error, any()}
  def get_participant_response(context_id, respondent_id) do
    adapter().get_participant_response(context_id, respondent_id)
  end

  # context_id conventions — the "mobilizon_" namespace prefix prevents collisions
  # when the same Adapter / Forms Service is shared between multiple applications.
  # Each new survey location requires only a new helper here and a new resolver callsite.
  # The Behaviour, ExternalAdapter, Adapter and Forms Service remain unchanged.

  @spec event_context_id(String.t() | integer()) :: String.t()
  def event_context_id(event_id), do: "mobilizon_event:#{event_id}"

  @spec group_context_id(String.t() | integer()) :: String.t()
  def group_context_id(group_id), do: "mobilizon_group:#{group_id}"

  @spec actor_respondent_id(String.t() | integer()) :: String.t()
  def actor_respondent_id(actor_id), do: "mobilizon_actor:#{actor_id}"
end
