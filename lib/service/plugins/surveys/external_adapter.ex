defmodule Mobilizon.Service.Plugins.Surveys.ExternalAdapter do
  @moduledoc """
  External HTTP adapter for the survey plugin. Communicates with an external survey service via Tesla.
  """
  @behaviour Mobilizon.Service.Plugins.Surveys

  require Logger

  @impl true
  def enabled?, do: true

  @impl true
  def check_gate(context_id, respondent_id) do
    Logger.debug("Survey check_gate: context=#{context_id}, respondent=#{respondent_id}")

    case Tesla.post(client(), "/api/check-gate", %{
           context_id: context_id,
           respondent_id: respondent_id
         }) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey gate check failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey gate check failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def submit_response(context_id, respondent_id, data) do
    case Tesla.post(client(), "/api/responses", %{
           context_id: context_id,
           respondent_id: respondent_id,
           data: data
         }) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 409, body: body}} ->
        {:error, "Survey response already submitted: #{inspect(body)}"}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey submit failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey submit failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def save_survey(context_id, schema) do
    # context_id may contain colons (e.g. "mobilizon_event:uuid"), so it must be
    # percent-encoded when used as a URL path segment.
    encoded = URI.encode(context_id, &URI.char_unreserved?/1)

    case Tesla.put(client(), "/api/surveys/by-context/#{encoded}", %{schema: schema}) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey save failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey save failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def get_responses(context_id) do
    encoded = URI.encode(context_id, &URI.char_unreserved?/1)

    case Tesla.get(client(), "/api/responses/by-context/#{encoded}") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey get responses failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey get responses failed: #{inspect(reason)}"}
    end
  end

  @spec client() :: Tesla.Client.t()
  defp client do
    config = Application.get_env(:mobilizon, Mobilizon.Service.Plugins.Surveys, [])

    middleware = [
      {Tesla.Middleware.BaseUrl, config[:adapter_url] || ""},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", "Bearer #{config[:api_key] || ""}"}]},
      {Tesla.Middleware.Timeout, timeout: 5_000}
    ]

    Tesla.client(middleware)
  end
end
