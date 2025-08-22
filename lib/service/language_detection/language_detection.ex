defmodule Mobilizon.Service.LanguageDetection do
  @moduledoc """
  Detect the language of the event
  """
  alias Mobilizon.Service.Formatter.HTML

  @und "und"

  # Temporarily disabled Paasaa due to Elixir 1.18.4 compatibility issues
  # @paasaa_languages Paasaa.Data.languages()
  #                   |> Map.values()
  #                   |> List.flatten()
  #                   |> Enum.map(fn {lang, _val} ->
  #                     lang
  #                   end)

  @allow_listed_locales Mobilizon.Cldr.known_locale_names()

  @type entity_type :: :event | :comment | :post

  @spec detect(entity_type(), map()) :: String.t()
  def detect(:event, %{title: _title} = _args) do
    # Temporarily return "en" instead of detecting language due to Paasaa compatibility issues
    "en"
  end

  def detect(:comment, %{text: _text}) do
    # Temporarily return "en" instead of detecting language due to Paasaa compatibility issues
    "en"
  end

  def detect(:post, %{title: _title} = _args) do
    # Temporarily return "en" instead of detecting language due to Paasaa compatibility issues
    "en"
  end

  def detect(_, _), do: @und

  @spec normalize(String.t()) :: String.t()
  def normalize(""), do: @und

  def normalize(language) do
    case Cldr.AcceptLanguage.parse(language, Mobilizon.Cldr) do
      {:ok, [{_, %Cldr.LanguageTag{} = tag}]} ->
        tag.language

      _ ->
        @und
    end
  end

  def allow_listed_languages do
    # Temporarily return empty list due to Paasaa compatibility issues
    []
  end
end
