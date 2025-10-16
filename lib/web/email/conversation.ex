defmodule Mobilizon.Web.Email.Conversation do
  @moduledoc """
  Handles emails sent about conversations/messages.
  """
  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email

  @doc """
  Send notification to a user when they receive a new message in a conversation
  """
  @spec notify_of_new_message(User.t(), Conversation.t(), Comment.t(), Actor.t()) ::
          Swoosh.Email.t()
  def notify_of_new_message(
        %User{email: email, locale: locale},
        %Conversation{} = conversation,
        %Comment{actor: %Actor{} = sender, text: text},
        %Actor{} = recipient_actor
      ) do
    require Logger

    # Use user's locale, fallback to "en" if nil
    locale = locale || "en"
    Logger.info("Setting email locale to: #{locale} for user #{email}")
    Gettext.put_locale(locale)

    # Get sender name
    sender_name = sender.name || sender.preferred_username

    subject =
      dgettext(
        "activity",
        "New message from %{sender}",
        sender: sender_name
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:conversation_new_message, %{
      locale: locale,
      conversation: conversation,
      sender: sender,
      recipient_actor: recipient_actor,
      message_text: text,
      sender_name: sender_name,
      subject: subject
    })
  end
end
