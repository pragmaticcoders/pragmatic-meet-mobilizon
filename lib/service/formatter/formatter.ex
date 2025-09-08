# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/formatter.ex

defmodule Mobilizon.Service.Formatter do
  @moduledoc """
  Formats input text to structured data, extracts mentions and hashtags.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Service.Formatter.HTML
  alias Phoenix.HTML.Tag

  alias Mobilizon.Web.Endpoint

  require Logger

  # https://github.com/rrrene/credo/issues/912
  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  @link_regex ~r"((?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~%:/?#[\]@!\$&'\(\)\*\+,;=.]+)|[0-9a-z+\-\.]+:[0-9a-z$-_.+!*'(),]+"ui
  @markdown_characters_regex ~r/(`|\*|_|{|}|[|]|\(|\)|#|\+|-|\.|!)/

  @spec escape_mention_handler(String.t(), String.t(), any(), any()) :: String.t()
  defp escape_mention_handler("@" <> nickname = mention, buffer, opts, context) do
    Logger.debug("[Formatter escape_mention_handler] Escaping mention")
    Logger.debug("[Formatter escape_mention_handler] Nickname: #{nickname}")
    Logger.debug("[Formatter escape_mention_handler] Mention: #{mention}")
    Logger.debug("[Formatter escape_mention_handler] Buffer: #{buffer}")
    Logger.debug("[Formatter escape_mention_handler] Options: #{inspect(opts)}")
    Logger.debug("[Formatter escape_mention_handler] Context: #{inspect(context)}")

    case ActivityPubActor.find_or_make_actor_from_nickname(nickname) do
      {:ok, %Actor{} = actor} ->
        Logger.debug("[Formatter escape_mention_handler] Found actor: #{inspect(actor)}")
        Logger.debug("[Formatter escape_mention_handler] Actor type: #{actor.type}")

        Logger.debug(
          "[Formatter escape_mention_handler] Actor preferred_username: #{actor.preferred_username}"
        )

        Logger.debug("[Formatter escape_mention_handler] Actor domain: #{actor.domain}")

        # escape markdown characters with `\\`
        # (we don't want something like @user__name to be parsed by markdown)
        escaped = String.replace(mention, @markdown_characters_regex, "\\\\\\1")
        Logger.debug("[Formatter escape_mention_handler] Escaped mention: #{escaped}")
        escaped

      {:error, err} ->
        Logger.debug("[Formatter escape_mention_handler] Failed to find actor: #{inspect(err)}")
        Logger.debug("[Formatter escape_mention_handler] Returning buffer: #{buffer}")
        buffer

      other ->
        Logger.debug("[Formatter escape_mention_handler] Unexpected result: #{inspect(other)}")
        buffer
    end
  end

  @spec mention_handler(String.t(), String.t(), any(), map()) :: {String.t(), map()}
  def mention_handler("@" <> nickname, buffer, opts, acc) do
    Logger.debug("[Formatter mention_handler] Processing mention")
    Logger.debug("[Formatter mention_handler] Nickname: #{nickname}")
    Logger.debug("[Formatter mention_handler] Buffer: #{buffer}")
    Logger.debug("[Formatter mention_handler] Options: #{inspect(opts)}")
    Logger.debug("[Formatter mention_handler] Accumulator: #{inspect(acc)}")

    case ActivityPubActor.find_or_make_actor_from_nickname(nickname) do
      {:ok, %Actor{type: :Person, id: id, preferred_username: preferred_username} = actor} ->
        Logger.debug("[Formatter mention_handler] Found Person actor: #{inspect(actor)}")
        Logger.debug("[Formatter mention_handler] Actor ID: #{id}")
        Logger.debug("[Formatter mention_handler] Preferred username: #{preferred_username}")
        Logger.debug("[Formatter mention_handler] Actor type: #{actor.type}")
        Logger.debug("[Formatter mention_handler] Actor domain: #{actor.domain}")

        link =
          Tag.content_tag(
            :span,
            [
              "@",
              Tag.content_tag(
                :span,
                preferred_username
              )
            ],
            "data-user": id,
            class: "h-card mention"
          )
          |> Phoenix.HTML.safe_to_string()

        Logger.debug("[Formatter mention_handler] Generated link: #{link}")

        new_acc = %{acc | mentions: MapSet.put(acc.mentions, {"@" <> nickname, actor})}
        Logger.debug("[Formatter mention_handler] Updated accumulator: #{inspect(new_acc)}")

        {link, new_acc}

      {:ok, %Actor{} = actor} ->
        Logger.debug(
          "[Formatter mention_handler] Found non-Person actor, ignoring: #{inspect(actor)}"
        )

        Logger.debug("[Formatter mention_handler] Actor type: #{actor.type}")
        {buffer, acc}

      {:error, err} ->
        Logger.debug("[Formatter mention_handler] Failed to find actor: #{inspect(err)}")
        {buffer, acc}

      other ->
        Logger.debug("[Formatter mention_handler] Unexpected result: #{inspect(other)}")
        {buffer, acc}
    end
  end

  @spec hashtag_handler(String.t(), String.t(), any(), map()) :: {String.t(), map()}
  def hashtag_handler("#" <> tag = tag_text, _buffer, _opts, acc) do
    tag = String.downcase(tag)
    url = "#{Endpoint.url()}/tag/#{tag}"

    link =
      Tag.content_tag(:a, tag_text,
        class: "hashtag",
        "data-tag": tag,
        href: url,
        rel: "tag ugc"
      )
      |> Phoenix.HTML.safe_to_string()

    {link, %{acc | tags: MapSet.put(acc.tags, {tag_text, tag})}}
  end

  @doc """
  Parses a text and replace plain text links with HTML. Returns a tuple with a result text, mentions, and hashtags.

  """
  @spec linkify(String.t(), keyword()) ::
          {String.t(), [{String.t(), Actor.t()}], [{String.t(), String.t()}]}
  def linkify(text, options \\ []) do
    Logger.debug("[Formatter linkify] Starting text linkification")
    Logger.debug("[Formatter linkify] Input text: #{text}")
    Logger.debug("[Formatter linkify] Input options: #{inspect(options)}")

    merged_options = linkify_opts() ++ options
    Logger.debug("[Formatter linkify] Merged options: #{inspect(merged_options)}")

    acc = %{mentions: MapSet.new(), tags: MapSet.new()}
    Logger.debug("[Formatter linkify] Initial accumulator: #{inspect(acc)}")

    {processed_text, %{mentions: mentions, tags: tags}} =
      Linkify.link_map(text, acc, merged_options)

    Logger.debug("[Formatter linkify] Processed text: #{processed_text}")
    Logger.debug("[Formatter linkify] Found mentions MapSet: #{inspect(mentions)}")
    Logger.debug("[Formatter linkify] Found tags MapSet: #{inspect(tags)}")

    mentions_list = MapSet.to_list(mentions)
    tags_list = MapSet.to_list(tags)

    Logger.debug("[Formatter linkify] Final mentions list: #{inspect(mentions_list)}")
    Logger.debug("[Formatter linkify] Final tags list: #{inspect(tags_list)}")

    # Log individual mentions
    Enum.each(mentions_list, fn {mention_text, actor} ->
      Logger.debug("[Formatter linkify] Mention: #{mention_text}")
      Logger.debug("[Formatter linkify] Mention actor: #{inspect(actor)}")
      Logger.debug("[Formatter linkify] Mention actor ID: #{actor.id}")

      Logger.debug(
        "[Formatter linkify] Mention actor preferred_username: #{actor.preferred_username}"
      )

      Logger.debug("[Formatter linkify] Mention actor domain: #{actor.domain}")
    end)

    result = {processed_text, mentions_list, tags_list}
    Logger.debug("[Formatter linkify] Final result: #{inspect(result)}")
    result
  end

  @doc """
  Escapes a special characters in mention names.
  """
  @spec mentions_escape(String.t(), Keyword.t()) :: String.t()
  def mentions_escape(text, options \\ []) do
    options =
      Keyword.merge(options,
        mention: true,
        url: false,
        mention_handler: &escape_mention_handler/4
      )

    Linkify.link(text, options)
  end

  @spec html_escape(
          {text :: String.t(), mentions :: list(), hashtags :: list()},
          type :: String.t()
        ) :: {String.t(), list(), list()}
  @spec html_escape(text :: String.t(), type :: String.t()) :: String.t()
  def html_escape({text, mentions, hashtags}, type) do
    {html_escape(text, type), mentions, hashtags}
  end

  def html_escape(text, "text/html") do
    with {:ok, content} <- HTML.filter_tags(text) do
      content
    end
  end

  def html_escape(text, "text/plain") do
    @link_regex
    |> Regex.split(text, include_captures: true)
    |> Enum.map_every(2, fn chunk ->
      {:safe, part} = Phoenix.HTML.html_escape(chunk)
      part
    end)
    |> Enum.join("")
  end

  @spec truncate(String.t(), non_neg_integer(), String.t()) :: String.t()
  def truncate(text, max_length \\ 200, omission \\ "...") do
    # Remove trailing whitespace
    text = Regex.replace(~r/([^ \t\r\n])([ \t]+$)/u, text, "\\g{1}")

    if String.length(text) < max_length do
      text
    else
      length_with_omission = max_length - String.length(omission)
      String.slice(text, 0, length_with_omission) <> omission
    end
  end

  @spec linkify_opts :: Keyword.t()
  defp linkify_opts do
    Mobilizon.Config.get(__MODULE__) ++
      [
        hashtag: true,
        hashtag_handler: &__MODULE__.hashtag_handler/4,
        mention: true,
        mention_handler: &__MODULE__.mention_handler/4
      ]
  end
end
