defmodule Mobilizon.Service.Plugins.Surveys.ExternalAdapter do
  @moduledoc """
  External HTTP adapter for the survey plugin. Communicates with an external survey service via Tesla.
  """
  @behaviour Mobilizon.Service.Plugins.Surveys

  require Logger

  @impl true
  def enabled?, do: true

  # ── Gate-check ───────────────────────────────────────────────────────────────

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
  def submit_response(context_id, respondent_id, data, survey_id \\ nil) do
    body =
      %{context_id: context_id, respondent_id: respondent_id, data: data}
      |> then(fn b -> if survey_id, do: Map.put(b, :survey_id, survey_id), else: b end)

    case Tesla.post(client(), "/api/responses", body) do
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
  def get_participant_response(context_id, respondent_id, survey_id) do
    encoded_respondent = URI.encode(respondent_id, &URI.char_unreserved?/1)

    path =
      if survey_id not in [nil, ""] do
        encoded_survey = URI.encode(survey_id, &URI.char_unreserved?/1)
        qs = URI.encode_query(%{"context_id" => context_id})

        "/api/responses/by-survey/#{encoded_survey}/by-respondent/#{encoded_respondent}?#{qs}"
      else
        encoded_context = URI.encode(context_id, &URI.char_unreserved?/1)

        "/api/responses/by-context/#{encoded_context}/by-respondent/#{encoded_respondent}"
      end

    case Tesla.get(client(), path) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 404}} ->
        {:ok, nil}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey get participant response failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey get participant response failed: #{inspect(reason)}"}
    end
  end

  # ── Survey lifecycle ─────────────────────────────────────────────────────────

  @impl true
  def list_surveys(context_id) do
    encoded = URI.encode(context_id, &URI.char_unreserved?/1)

    case Tesla.get(client(), "/api/surveys/by-context/#{encoded}") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 404}} ->
        {:ok, []}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey list failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey list failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def get_survey(survey_id) do
    encoded = URI.encode(survey_id, &URI.char_unreserved?/1)

    case Tesla.get(client(), "/api/surveys/#{encoded}") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 404}} ->
        {:error, :not_found}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey get failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey get failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def create_survey(context_id, attrs) do
    encoded = URI.encode(context_id, &URI.char_unreserved?/1)

    case Tesla.post(client(), "/api/surveys/by-context/#{encoded}", attrs) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey create failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey create failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def update_survey(survey_id, attrs) do
    encoded = URI.encode(survey_id, &URI.char_unreserved?/1)

    case Tesla.patch(client(), "/api/surveys/#{encoded}", attrs) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey update failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey update failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def publish_survey(survey_id) do
    encoded = URI.encode(survey_id, &URI.char_unreserved?/1)

    case Tesla.post(client(), "/api/surveys/#{encoded}/publish", %{}) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey publish failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey publish failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def close_survey(survey_id) do
    encoded = URI.encode(survey_id, &URI.char_unreserved?/1)

    case Tesla.post(client(), "/api/surveys/#{encoded}/close", %{}) do
      {:ok, %Tesla.Env{status: status, body: body}} when status in [200, 201] ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey close failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey close failed: #{inspect(reason)}"}
    end
  end

  @impl true
  def get_survey_responses(survey_id) do
    encoded = URI.encode(survey_id, &URI.char_unreserved?/1)

    case Tesla.get(client(), "/api/surveys/#{encoded}/responses") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Survey get responses failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Survey get responses failed: #{inspect(reason)}"}
    end
  end

  # ── Kept for backward compat (gate-check flow) ───────────────────────────────

  @impl true
  def save_survey(context_id, schema) do
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

      # No survey exists yet for this context (e.g. gate-check survey before anyone joins)
      {:ok, %Tesla.Env{status: 404}} ->
        {:ok, []}

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
