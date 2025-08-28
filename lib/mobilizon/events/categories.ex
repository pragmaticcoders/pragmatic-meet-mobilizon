defmodule Mobilizon.Events.Categories do
  @moduledoc """
  Module that handles event categories
  """
  import Mobilizon.Web.Gettext

  @default "SOCIAL_ACTIVITIES"

  @spec default :: String.t()
  def default do
    @default
  end

  @spec list :: [%{id: atom(), label: String.t()}]
  def list do
    build_in_categories() ++ extra_categories()
  end

  @spec get_category(String.t() | nil) :: String.t()
  def get_category(category) do
    if category in Enum.map(list(), &String.upcase(to_string(&1.id))) do
      category
    else
      default()
    end
  end

  defp build_in_categories do
    [
      %{
        id: :art_and_culture,
        label: gettext("Art & Culture")
      },
      %{
        id: :career_and_business,
        label: gettext("Career & Business")
      },
      %{
        id: :community_and_environment,
        label: gettext("Community & Environment")
      },
      %{
        id: :dance,
        label: gettext("Dance")
      },
      %{
        id: :games,
        label: gettext("Games")
      },
      %{
        id: :hobbies_and_passions,
        label: gettext("Hobbies & Passions")
      },
      %{
        id: :identity_and_language,
        label: gettext("Identity & Language")
      },
      %{
        id: :movement_and_politics,
        label: gettext("Movement & Politics")
      },
      %{
        id: :music,
        label: gettext("Music")
      },
      %{
        id: :parents_and_family,
        label: gettext("Parents & Family")
      },
      %{
        id: :pets_and_animals,
        label: gettext("Pets & Animals")
      },
      %{
        id: :religion_and_spirituality,
        label: gettext("Religion & Spirituality")
      },
      %{
        id: :science_and_education,
        label: gettext("Science & Education")
      },
      %{
        id: :social_activities,
        label: gettext("Social Activities")
      },
      %{
        id: :sports_and_fitness,
        label: gettext("Sports & Fitness")
      },
      %{
        id: :technology,
        label: gettext("Technology")
      },
      %{
        id: :travel_and_outdoor,
        label: gettext("Travel & Outdoor")
      },
      %{
        id: :wellness,
        label: gettext("Wellness")
      },
      %{
        id: :writing,
        label: gettext("Writing")
      }
    ]
  end

  @spec extra_categories :: [%{id: atom(), label: String.t()}]
  defp extra_categories do
    :mobilizon
    |> Application.get_env(:instance)
    |> Keyword.get(:extra_categories, [])
  end
end
