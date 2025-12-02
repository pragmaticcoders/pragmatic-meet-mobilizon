defmodule Mobilizon.Web.Email.Group do
  @moduledoc """
  Handles emails sent about group changes.
  """
  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.{Actors, Config, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.Event
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email
  require Logger

  @spec notify_of_new_event(Event.t()) :: :ok
  def notify_of_new_event(%Event{attributed_to: %Actor{} = group} = event) do
    # TODO: When we have events restricted to members, don't send emails to followers
    group
    |> Actors.list_actors_to_notify_from_group_event()
    |> Enum.reduce([], fn actor, users ->
      # No emails for remote actors
      if is_nil(actor.user_id) do
        users
      else
        users ++ [Users.get_user_with_activity_settings!(actor.user_id)]
      end
    end)
    |> Enum.uniq_by(& &1.email)
    |> Enum.each(&notify_follower(event, group, &1))
  end

  def notify_of_new_event(%Event{}), do: :ok

  defp notify_follower(%Event{} = event, %Actor{type: :Group} = group, %User{} = user) do
    with %User{
           email: email,
           locale: locale,
           settings: settings,
           activity_settings: activity_settings,
           default_actor_id: default_actor_id
         } <- user,
         true <- default_actor_id != event.organizer_actor_id,
         true <- accepts_new_events_notifications(activity_settings) do
      timezone = if settings, do: settings.timezone, else: nil
      Gettext.put_locale(locale || "en")

      subject =
        gettext(
          "📅 Just scheduled by %{group}: %{event}",
          group: Actor.display_name(group),
          event: event.title
        )

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:event_group_follower_notification, %{
        locale: locale || "en",
        group: group,
        event: event,
        timezone: timezone,
        subject: subject
      })
      |> Email.Mailer.send_email()

      :ok
    else
      false ->
        :ok

      _ ->
        Logger.error(
          "Unable to notify group follower user #{user.email} for event #{event.uuid} from group #{group.preferred_username} - missing required user data"
        )

        :ok
    end
  end

  defp notify_follower(_, _, _), do: :ok

  @spec accepts_new_events_notifications(list()) :: boolean()
  defp accepts_new_events_notifications(activity_settings) do
    case Enum.find(activity_settings, &(&1.key == "event_created" && &1.method == "email")) do
      nil ->
        # Default to true when no setting exists (matches frontend default behavior)
        true

      %{enabled: enabled} ->
        enabled
    end
  end

  @member_roles [:administrator, :moderator, :member]
  @spec send_group_suspension_notification(Member.t()) :: :ok
  def send_group_suspension_notification(%Member{actor: %Actor{user_id: nil}}), do: :ok

  def send_group_suspension_notification(%Member{role: role}) when role not in @member_roles,
    do: :ok

  def send_group_suspension_notification(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{domain: nil} = group,
        role: member_role
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "The group %{group} has been suspended on %{instance}",
          group: group.name,
          instance: Config.instance_name()
        )

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:group_suspension, %{
        locale: locale,
        group: group,
        role: member_role,
        subject: subject
      })
      |> Email.Mailer.send_email()

      :ok
    end
  end
end
