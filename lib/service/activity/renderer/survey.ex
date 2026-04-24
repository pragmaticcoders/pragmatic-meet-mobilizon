defmodule Mobilizon.Service.Activity.Renderer.Survey do
  @moduledoc """
  Renders a survey activity for push notifications.
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Activity.Renderer
  use Mobilizon.Web, :verified_routes
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  @behaviour Renderer

  @impl Renderer
  def render(%Activity{subject: :survey_published} = activity, options) do
    locale = Keyword.get(options, :locale, "en")
    Gettext.put_locale(locale)

    context_type = activity.subject_params["context_type"]

    %{
      body: body(context_type, activity),
      url: survey_url(context_type, activity)
    }
  end

  defp body("event", activity) do
    dgettext(
      "activity",
      "The survey %{survey} was published by %{profile} in the event %{event}.",
      %{
        profile: profile(activity),
        survey: survey_title(activity),
        event: event_title(activity)
      }
    )
  end

  defp body("group", activity) do
    dgettext(
      "activity",
      "The survey %{survey} was published by %{profile} in the group %{group}.",
      %{
        profile: profile(activity),
        survey: survey_title(activity),
        group: group(activity)
      }
    )
  end

  defp body(_, activity), do: body("group", activity)

  defp survey_url("event", activity) do
    event_uuid = activity.subject_params["event_uuid"]
    if event_uuid, do: URI.decode(~p"/events/#{event_uuid}"), else: nil
  end

  defp survey_url("group", activity) do
    if activity.group do
      URI.decode(~p"/@#{activity.group.preferred_username}")
    end
  end

  defp survey_url(_, activity), do: survey_url("group", activity)

  defp profile(activity), do: Actor.display_name_and_username(activity.author)
  defp survey_title(activity), do: activity.subject_params["survey_title"] || ""
  defp event_title(activity), do: activity.subject_params["event_title"] || ""
  defp group(activity), do: Actor.display_name_and_username(activity.group)
end
