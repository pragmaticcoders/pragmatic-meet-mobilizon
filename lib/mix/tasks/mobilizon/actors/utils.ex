defmodule Mix.Tasks.Mobilizon.Actors.Utils do
  @moduledoc """
  Tools for generating usernames from display names
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @doc """
  Removes all spaces, accents, special characters and diacritics from a string to create a plain ascii username (a-z0-9_)
  Includes proper transliteration for Polish and other European characters.

  See https://stackoverflow.com/a/37511463
  """
  @spec generate_username(String.t()) :: String.t()
  def generate_username(""), do: ""

  def generate_username(name) do
    # Character transliteration map for Polish and other European characters
    transliteration_map = %{
      # Polish characters
      "ą" => "a", "ć" => "c", "ę" => "e", "ł" => "l", "ń" => "n", "ó" => "o", "ś" => "s", "ź" => "z", "ż" => "z",
      "Ą" => "A", "Ć" => "C", "Ę" => "E", "Ł" => "L", "Ń" => "N", "Ó" => "O", "Ś" => "S", "Ź" => "Z", "Ż" => "Z",
      
      # Other European characters
      "ä" => "a", "ö" => "o", "ü" => "u", "ß" => "ss",
      "Ä" => "A", "Ö" => "O", "Ü" => "U",
      "à" => "a", "á" => "a", "â" => "a", "ã" => "a", "å" => "a", "æ" => "ae",
      "À" => "A", "Á" => "A", "Â" => "A", "Ã" => "A", "Å" => "A", "Æ" => "AE",
      "è" => "e", "é" => "e", "ê" => "e", "ë" => "e",
      "È" => "E", "É" => "E", "Ê" => "E", "Ë" => "E",
      "ì" => "i", "í" => "i", "î" => "i", "ï" => "i",
      "Ì" => "I", "Í" => "I", "Î" => "I", "Ï" => "I",
      "ò" => "o", "ô" => "o", "õ" => "o", "ø" => "o",
      "Ò" => "O", "Ô" => "O", "Õ" => "O", "Ø" => "O",
      "ù" => "u", "ú" => "u", "û" => "u",
      "Ù" => "U", "Ú" => "U", "Û" => "U",
      "ý" => "y", "ÿ" => "y",
      "Ý" => "Y", "Ÿ" => "Y",
      "ñ" => "n", "Ñ" => "N",
      "ç" => "c", "Ç" => "C",
      "ð" => "d", "Ð" => "D",
      "þ" => "th", "Þ" => "TH"
    }

    name
    |> String.downcase()
    # Apply transliteration first
    |> String.replace(~r/[ąćęłńóśźżäöüßàáâãåæèéêëìíîïòôõøùúûýÿñçðþ]/u, fn char ->
      Map.get(transliteration_map, char, char)
    end)
    # Then normalize and remove combining diacritical marks (for remaining accented characters)
    |> String.normalize(:nfd)
    |> String.replace(~r/[\x{0300}-\x{036f}]/u, "")
    |> String.replace(~r/ /, "_")
    |> String.replace(~r/[^a-z0-9_]/, "")
  end

  # Profile from name
  @spec username_and_name(String.t() | nil, String.t() | nil) :: {String.t(), String.t()}
  def username_and_name(nil, profile_name) do
    {generate_username(profile_name), profile_name}
  end

  def username_and_name(profile_username, nil) do
    {profile_username, profile_username}
  end

  def username_and_name(profile_username, profile_name) do
    {profile_username, profile_name}
  end

  def create_profile(%User{id: user_id}, username, name, options \\ []) do
    {username, name} = username_and_name(username, name)

    {:ok, %Actor{} = new_person} =
      Actors.new_person(
        %{preferred_username: username, user_id: user_id, name: name},
        Keyword.get(options, :default, true)
      )

    new_person
  end

  @spec create_group(Actor.t(), String.t(), String.t()) ::
          {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def create_group(%Actor{id: admin_id}, username, name) do
    {username, name} = username_and_name(username, name)

    Actors.create_group(%{creator_actor_id: admin_id, preferred_username: username, name: name})
  end
end
