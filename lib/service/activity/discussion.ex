defmodule Mobilizon.Service.Activity.Discussion do
  @moduledoc """
  Insert a discussion activity
  """
  alias Mobilizon.{Actors, Discussions}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.{ActivityBuilder, LegacyNotifierBuilder}

  import Mobilizon.Service.Activity.Utils, only: [maybe_inserted_at: 0]

  require Logger

  @behaviour Activity

  @impl Activity
  def insert_activity(discussion, options \\ [])

  def insert_activity(
        %Discussion{creator_id: creator_id, actor_id: actor_id} = discussion,
        options
      )
      when not is_nil(creator_id) do
    creator = Actors.get_actor(creator_id)
    group = Actors.get_actor(actor_id)
    subject = Keyword.fetch!(options, :subject)
    author = Keyword.get(options, :moderator, creator)
    author_id = Keyword.get(options, :actor_id, author.id)
    old_discussion = Keyword.get(options, :old_discussion)

    Logger.debug("[Discussion insert_activity] Calling send_mention_notifications")
    Logger.debug("[Discussion insert_activity] Subject: #{subject}")
    Logger.debug("[Discussion insert_activity] Discussion: #{inspect(discussion)}")
    Logger.debug("[Discussion insert_activity] Last comment: #{inspect(discussion.last_comment)}")
    Logger.debug("[Discussion insert_activity] Options: #{inspect(options)}")

    send_mention_notifications(subject, discussion, discussion.last_comment, options)

    ActivityBuilder.enqueue(
      :build_activity,
      %{
        "type" => "discussion",
        "subject" => subject,
        "subject_params" => subject_params(discussion, subject, old_discussion),
        "group_id" => group.id,
        "author_id" => author_id,
        "object_type" => "discussion",
        "object_id" =>
          if(subject != "discussion_deleted", do: to_string(discussion.id), else: nil)
      }
      |> Map.merge(maybe_inserted_at())
    )
  end

  def insert_activity(_, _), do: {:ok, nil}

  @impl Activity
  def get_object(discussion_id) do
    Discussions.get_discussion(discussion_id)
  end

  @spec subject_params(Discussion.t(), String.t() | nil, Discussion.t() | nil) :: map()
  defp subject_params(%Discussion{} = discussion, "discussion_renamed", old_discussion) do
    discussion
    |> subject_params(nil, nil)
    |> Map.put(:old_discussion_title, old_discussion.title)
  end

  defp subject_params(%Discussion{} = discussion, _, _) do
    %{discussion_slug: discussion.slug, discussion_title: discussion.title}
  end

  # An actor is mentionned
  @spec send_mention_notifications(String.t(), Discussion.t(), Comment.t(), Keyword.t()) ::
          {:ok, Oban.Job.t()} | {:ok, :skipped}
  defp send_mention_notifications(
         subject,
         %Discussion{
           id: discussion_id,
           title: title,
           slug: slug,
           actor: %Actor{id: group_id, type: :Group}
         } = discussion,
         %Comment{actor_id: actor_id, mentions: mentions} = comment,
         options
       )
       when subject in ["discussion_created", "discussion_replied"] and length(mentions) > 0 do
    Logger.debug("[Discussion send_mention_notifications] Processing mention notifications")
    Logger.debug("[Discussion send_mention_notifications] Subject: #{subject}")
    Logger.debug("[Discussion send_mention_notifications] Discussion: #{inspect(discussion)}")
    Logger.debug("[Discussion send_mention_notifications] Discussion ID: #{discussion_id}")
    Logger.debug("[Discussion send_mention_notifications] Discussion title: #{title}")
    Logger.debug("[Discussion send_mention_notifications] Discussion slug: #{slug}")
    Logger.debug("[Discussion send_mention_notifications] Group ID: #{group_id}")
    Logger.debug("[Discussion send_mention_notifications] Comment: #{inspect(comment)}")
    Logger.debug("[Discussion send_mention_notifications] Comment actor ID: #{actor_id}")
    Logger.debug("[Discussion send_mention_notifications] Mentions: #{inspect(mentions)}")
    Logger.debug("[Discussion send_mention_notifications] Mention count: #{length(mentions)}")
    Logger.debug("[Discussion send_mention_notifications] Options: #{inspect(options)}")

    # Log individual mentions
    Enum.each(mentions, fn mention ->
      Logger.debug(
        "[Discussion send_mention_notifications] Processing mention: #{inspect(mention)}"
      )

      Logger.debug(
        "[Discussion send_mention_notifications] Mention actor_id: #{mention.actor_id}"
      )

      if mention.actor do
        Logger.debug(
          "[Discussion send_mention_notifications] Mention actor: #{inspect(mention.actor)}"
        )
      else
        Logger.debug("[Discussion send_mention_notifications] Mention actor not loaded")
      end
    end)

    mention_actor_ids = Enum.map(mentions, & &1.actor_id)

    Logger.debug(
      "[Discussion send_mention_notifications] Extracted actor IDs: #{inspect(mention_actor_ids)}"
    )

    notification_params = %{
      "subject" => :discussion_mention,
      "subject_params" => %{
        discussion_slug: slug,
        discussion_title: title
      },
      "type" => :discussion,
      "object_type" => :discussion,
      "author_id" => actor_id,
      "group_id" => group_id,
      "object_id" => to_string(discussion_id),
      "mentions" => mention_actor_ids
    }

    Logger.debug(
      "[Discussion send_mention_notifications] Notification params: #{inspect(notification_params)}"
    )

    result = LegacyNotifierBuilder.enqueue(:legacy_notify, notification_params)
    Logger.debug("[Discussion send_mention_notifications] Enqueue result: #{inspect(result)}")

    {:ok, :enqueued}
  end

  defp send_mention_notifications(subject, discussion, comment, options) do
    Logger.debug(
      "[Discussion send_mention_notifications] Fallback clause - skipping notifications"
    )

    Logger.debug("[Discussion send_mention_notifications] Subject: #{subject}")
    Logger.debug("[Discussion send_mention_notifications] Discussion: #{inspect(discussion)}")
    Logger.debug("[Discussion send_mention_notifications] Comment: #{inspect(comment)}")
    Logger.debug("[Discussion send_mention_notifications] Options: #{inspect(options)}")

    # Log specific reasons for skipping
    cond do
      subject not in ["discussion_created", "discussion_replied"] ->
        Logger.debug(
          "[Discussion send_mention_notifications] Skipping: subject '#{subject}' not in allowed subjects"
        )

      is_nil(comment) ->
        Logger.debug("[Discussion send_mention_notifications] Skipping: comment is nil")

      !Map.has_key?(comment, :mentions) ->
        Logger.debug(
          "[Discussion send_mention_notifications] Skipping: comment has no mentions field"
        )

      is_nil(comment.mentions) ->
        Logger.debug("[Discussion send_mention_notifications] Skipping: comment mentions is nil")

      length(comment.mentions) == 0 ->
        Logger.debug("[Discussion send_mention_notifications] Skipping: no mentions in comment")

      true ->
        Logger.debug(
          "[Discussion send_mention_notifications] Skipping: other pattern matching issue"
        )
    end

    {:ok, :skipped}
  end
end
