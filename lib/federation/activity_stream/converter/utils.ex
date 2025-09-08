defmodule Mobilizon.Federation.ActivityStream.Converter.Utils do
  @moduledoc """
  Various utils for converters.
  """

  alias Mobilizon.{Actors, Addresses, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Tag
  alias Mobilizon.Medias.Media
  alias Mobilizon.Mention
  alias Mobilizon.Storage.Repo

  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream.Converter.Address, as: AddressConverter
  alias Mobilizon.Federation.ActivityStream.Converter.Media, as: MediaConverter

  alias Mobilizon.Web.Endpoint

  require Logger

  @banner_picture_name "Banner"

  @spec fetch_tags([String.t()]) :: [Tag.t()]
  def fetch_tags(tags) when is_list(tags) do
    Logger.debug("fetching tags")
    Logger.debug(inspect(tags))

    tags
    |> Enum.flat_map(&fetch_tag/1)
    |> Enum.uniq()
    |> Enum.filter(& &1)
    |> Enum.map(&existing_tag_or_data/1)
  end

  def fetch_tags(_), do: []

  @spec fetch_mentions([map()]) :: [map()]
  def fetch_mentions(mentions) when is_list(mentions) do
    Logger.debug("[fetch_mentions] Starting mention processing")
    Logger.debug("[fetch_mentions] Input mentions: #{inspect(mentions)}")
    Logger.debug("[fetch_mentions] Mention count: #{length(mentions)}")

    result =
      Enum.reduce(mentions, [], fn mention, acc ->
        Logger.debug("[fetch_mentions] Processing mention: #{inspect(mention)}")
        new_acc = create_mention(mention, acc)
        Logger.debug("[fetch_mentions] Accumulator after processing: #{inspect(new_acc)}")
        new_acc
      end)

    Logger.debug("[fetch_mentions] Final result: #{inspect(result)}")
    Logger.debug("[fetch_mentions] Final result count: #{length(result)}")
    result
  end

  def fetch_mentions(_), do: []

  def fetch_actors(actors) when is_list(actors) do
    Logger.debug("fetching contacts")
    actors |> Enum.map(& &1.id) |> Enum.filter(& &1) |> Enum.map(&Actors.get_actor/1)
  end

  def fetch_actors(_), do: []

  @spec build_tags([Tag.t()]) :: [map()]
  def build_tags(tags) do
    Enum.map(tags, fn %Tag{} = tag ->
      %{
        "href" => Endpoint.url() <> "/tags/#{tag.slug}",
        "name" => "##{tag.title}",
        "type" => "Hashtag"
      }
    end)
  end

  def build_mentions(mentions) do
    Logger.debug("[build_mentions] Starting mention building")
    Logger.debug("[build_mentions] Input mentions: #{inspect(mentions)}")
    Logger.debug("[build_mentions] Mention count: #{length(mentions)}")

    result =
      Enum.map(mentions, fn %Mention{} = mention ->
        Logger.debug("[build_mentions] Processing mention: #{inspect(mention)}")

        Logger.debug(
          "[build_mentions] Mention actor loaded?: #{Ecto.assoc_loaded?(mention.actor)}"
        )

        actor =
          if Ecto.assoc_loaded?(mention.actor) do
            Logger.debug("[build_mentions] Using preloaded actor: #{inspect(mention.actor)}")
            mention.actor
          else
            Logger.debug("[build_mentions] Loading actor from database")
            preloaded_mention = Repo.preload(mention, [:actor])
            Logger.debug("[build_mentions] Preloaded mention: #{inspect(preloaded_mention)}")
            preloaded_mention.actor
          end

        Logger.debug("[build_mentions] Final actor for mention: #{inspect(actor)}")
        built_mention = build_mention(actor)
        Logger.debug("[build_mentions] Built mention result: #{inspect(built_mention)}")
        built_mention
      end)

    Logger.debug("[build_mentions] Final result: #{inspect(result)}")
    result
  end

  defp build_mention(%Actor{} = actor) do
    Logger.debug("[build_mention] Building mention for actor: #{inspect(actor)}")
    Logger.debug("[build_mention] Actor URL: #{actor.url}")
    Logger.debug("[build_mention] Actor preferred_username: #{actor.preferred_username}")
    Logger.debug("[build_mention] Actor domain: #{actor.domain}")

    username_and_domain = Actor.preferred_username_and_domain(actor)
    Logger.debug("[build_mention] Generated username_and_domain: #{username_and_domain}")

    result = %{
      "href" => actor.url,
      "name" => "@#{username_and_domain}",
      "type" => "Mention"
    }

    Logger.debug("[build_mention] Final mention result: #{inspect(result)}")
    result
  end

  defp fetch_tag(%{title: title}), do: [title]

  defp fetch_tag(tag) when is_map(tag) do
    case tag["type"] do
      "Hashtag" ->
        [tag_without_hash(tag["name"])]

      _err ->
        []
    end
  end

  defp fetch_tag(tag) when is_binary(tag), do: [tag_without_hash(tag)]

  defp tag_without_hash("#" <> tag_title), do: tag_title
  defp tag_without_hash(tag_title), do: tag_title

  defp existing_tag_or_data(tag_title) do
    case Events.get_tag_by_title(tag_title) do
      %Tag{} = tag -> %{title: tag.title, id: tag.id}
      nil -> %{title: tag_title}
    end
  end

  @spec create_mention(map(), list()) :: list()
  defp create_mention(%Actor{id: actor_id} = mention, acc) do
    Logger.debug("[create_mention] Processing Actor mention: #{inspect(mention)}")
    Logger.debug("[create_mention] Actor ID: #{actor_id}")
    Logger.debug("[create_mention] Current accumulator: #{inspect(acc)}")

    result = acc ++ [%{actor_id: actor_id}]
    Logger.debug("[create_mention] New accumulator: #{inspect(result)}")
    result
  end

  defp create_mention(mention, acc) when is_map(mention) do
    Logger.debug("[create_mention] Processing map mention: #{inspect(mention)}")
    Logger.debug("[create_mention] Mention type: #{mention["type"]}")
    Logger.debug("[create_mention] Mention href: #{mention["href"]}")
    Logger.debug("[create_mention] Current accumulator: #{inspect(acc)}")

    with true <- mention["type"] == "Mention" do
      Logger.debug("[create_mention] Type is Mention, fetching actor")

      case ActivityPubActor.get_or_fetch_actor_by_url(mention["href"]) do
        {:ok, %Actor{id: actor_id} = actor} ->
          Logger.debug("[create_mention] Successfully fetched actor: #{inspect(actor)}")
          Logger.debug("[create_mention] Actor ID: #{actor_id}")
          result = acc ++ [%{actor_id: actor_id}]
          Logger.debug("[create_mention] New accumulator: #{inspect(result)}")
          result

        {:error, err} ->
          Logger.debug("[create_mention] Failed to fetch actor: #{inspect(err)}")
          acc

        other ->
          Logger.debug("[create_mention] Unexpected result from actor fetch: #{inspect(other)}")
          acc
      end
    else
      false ->
        Logger.debug("[create_mention] Type is not Mention, skipping")
        acc

      other ->
        Logger.debug("[create_mention] Unexpected type check result: #{inspect(other)}")
        acc
    end
  end

  @spec create_mention({String.t(), map()}, list()) :: list()
  defp create_mention({key, mention}, acc) when is_map(mention) do
    Logger.debug("[create_mention] Processing tuple mention with key: #{key}")
    Logger.debug("[create_mention] Mention data: #{inspect(mention)}")
    create_mention(mention, acc)
  end

  defp create_mention(mention, acc) do
    Logger.debug("[create_mention] Fallback clause - unhandled mention type: #{inspect(mention)}")
    Logger.debug("[create_mention] Returning unchanged accumulator: #{inspect(acc)}")
    acc
  end

  @spec maybe_fetch_actor_and_attributed_to_id(map()) ::
          {:ok, Actor.t(), Actor.t() | nil} | {:error, atom()}
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when is_nil(attributed_to_url) do
    case fetch_actor(actor_url) do
      {:ok, %Actor{} = actor} ->
        {:ok, actor, nil}

      {:error, err} ->
        {:error, err}
    end
  end

  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when is_nil(actor_url) do
    case fetch_actor(attributed_to_url) do
      {:ok, %Actor{} = actor} ->
        {:ok, actor, nil}

      {:error, err} ->
        {:error, err}
    end
  end

  # Only when both actor and attributedTo fields are both filled is when we can return both
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when actor_url != attributed_to_url do
    with {:ok, %Actor{} = actor} <- fetch_actor(actor_url),
         {:ok, %Actor{} = attributed_to} <- fetch_actor(attributed_to_url) do
      {:ok, actor, attributed_to}
    else
      {:error, err} ->
        {:error, err}
    end
  end

  # If we only have attributedTo and no actor, take attributedTo as the actor
  def maybe_fetch_actor_and_attributed_to_id(%{
        "attributedTo" => attributed_to_url
      }) do
    case fetch_actor(attributed_to_url) do
      {:ok, %Actor{} = attributed_to} -> {:ok, attributed_to, nil}
      {:error, err} -> {:error, err}
    end
  end

  def maybe_fetch_actor_and_attributed_to_id(_), do: {:error, :no_actor_found}

  @spec fetch_actor(String.t() | map()) :: {:ok, Actor.t()} | {:error, atom()}
  def fetch_actor(%{"id" => actor_url}) when is_binary(actor_url), do: fetch_actor(actor_url)

  def fetch_actor(actor_url) when is_binary(actor_url) do
    case ActivityPubActor.get_or_fetch_actor_by_url(actor_url) do
      {:ok, %Actor{suspended: false} = actor} ->
        {:ok, actor}

      {:ok, %Actor{suspended: true} = _actor} ->
        {:error, :actor_suspended}

      {:error, err} ->
        {:error, err}
    end
  end

  def fetch_actor(_), do: {:error, :no_actor_found}

  @spec process_pictures(map(), integer()) :: Keyword.t()
  def process_pictures(object, actor_id) do
    {banner, media_attachements} = get_medias(object)

    media_attachements_map =
      media_attachements
      |> Enum.map(fn media_attachement ->
        {media_attachement["url"],
         MediaConverter.find_or_create_media(media_attachement, actor_id)}
      end)
      |> Enum.reduce(%{}, fn {old_url, media}, acc ->
        case media do
          {:ok, %Media{} = media} ->
            Map.put(acc, old_url, media)

          _ ->
            acc
        end
      end)

    media_attachements_map_urls =
      media_attachements_map
      |> Enum.map(fn {old_url, new_media} -> {old_url, new_media.file.url} end)
      |> Map.new()

    picture_id =
      case banner do
        banner_map when is_map(banner_map) ->
          case MediaConverter.find_or_create_media(banner_map, actor_id) do
            {:error, _err} ->
              nil

            {:ok, %Media{id: picture_id}} ->
              picture_id
          end

        _ ->
          nil
      end

    description = replace_media_urls_in_body(object["content"], media_attachements_map_urls)
    [description: description, picture_id: picture_id, medias: Map.values(media_attachements_map)]
  end

  defp replace_media_urls_in_body(body, media_urls),
    do:
      Enum.reduce(media_urls, body, fn media_url, body ->
        replace_media_url_in_body(body, media_url)
      end)

  defp replace_media_url_in_body(body, {old_url, new_url}),
    do: String.replace(body, old_url, new_url)

  @spec get_medias(list(map())) :: {map(), list(map())}
  def get_medias(object) do
    banner = get_banner_picture(object)
    attachments = Map.get(object, "attachment", [])
    {banner, Enum.filter(attachments, &(valid_banner_media?(&1) && &1["url"] != banner["url"]))}
  end

  @spec get_banner_picture(map()) :: map()
  defp get_banner_picture(object) do
    attachments = Map.get(object, "attachment", [])
    image = Map.get(object, "image", %{})

    media_with_picture_name =
      Enum.find(attachments, &(valid_banner_media?(&1) && &1["name"] == @banner_picture_name))

    cond do
      # Check if the "image" key is set and of type "Document" or "Image"
      is_nil(media_with_picture_name) and valid_banner_media?(image) ->
        image

      is_nil(media_with_picture_name) and Enum.find(attachments, &valid_banner_media?/1) ->
        Enum.find(attachments, &valid_banner_media?/1)

      !is_nil(media_with_picture_name) ->
        media_with_picture_name

      true ->
        nil
    end
  end

  @spec valid_banner_media?(map()) :: boolean()
  defp valid_banner_media?(media) do
    media |> Map.get("type") |> valid_attachment_type?()
  end

  @spec valid_attachment_type?(any()) :: boolean()
  defp valid_attachment_type?(type) do
    type in ["Document", "Image"]
  end

  @spec get_address(map | binary | nil) :: Address.t() | nil
  def get_address(text_address) when is_binary(text_address) do
    get_address(%{"type" => "Place", "name" => text_address})
  end

  def get_address(%{"id" => url} = map) when is_map(map) and is_binary(url) do
    Logger.debug("Address with an URL, let's check against our own database")

    case Addresses.get_address_by_url(url) do
      %Address{} = address ->
        address

      _ ->
        Logger.debug("not in our database, let's try to create it")
        # This is odd, why do addresses have url instead of just @id?
        map = Map.put(map, "url", map["id"])
        do_get_address(map)
    end
  end

  def get_address(map) when is_map(map) do
    do_get_address(map)
  end

  def get_address(nil), do: nil

  @spec do_get_address(map) :: Address.t() | nil
  defp do_get_address(map) do
    map = AddressConverter.as_to_model_data(map)

    case Addresses.create_address(map) do
      {:ok, %Address{} = address} ->
        address

      _ ->
        nil
    end
  end

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  @spec visibility_public?(String.t() | list(String.t())) :: boolean()
  def visibility_public?(to) when is_binary(to), do: visibility_public?([to])

  def visibility_public?(to) when is_list(to) do
    !MapSet.disjoint?(MapSet.new(to), MapSet.new([@ap_public, "as:Public", "Public"]))
  end
end
