defmodule Mobilizon.Web.AuthView do
  @moduledoc """
  View for the auth routes
  """

  use Mobilizon.Web, :view
  alias Mobilizon.Service.Metadata.Instance
  alias Mobilizon.Web.PageView
  alias Phoenix.HTML.Tag

  @spec render(String.t(), map()) :: String.t() | Plug.Conn.t()
  def render(
        "callback.html",
        %{
          conn: _conn,
          access_token: access_token,
          refresh_token: refresh_token,
          user: user,
          username: username,
          name: name
        } = assigns
      ) do
    # Handle both existing users (with default_actor_id) and new users (without default_actor_id)
    user_actor_id = Map.get(user, :default_actor_id, nil)

    info_tags = [
      Tag.tag(:meta, name: "auth-access-token", content: access_token),
      Tag.tag(:meta, name: "auth-refresh-token", content: refresh_token),
      Tag.tag(:meta, name: "auth-user-id", content: user.id),
      Tag.tag(:meta, name: "auth-user-email", content: user.email),
      Tag.tag(:meta, name: "auth-user-role", content: String.upcase(to_string(user.role))),
      Tag.tag(:meta, name: "auth-user-actor-id", content: user_actor_id),
      Tag.tag(:meta, name: "auth-user-suggested-actor-username", content: username),
      Tag.tag(:meta, name: "auth-user-suggested-actor-name", content: name)
    ]

    with tags <- Instance.build_tags() ++ info_tags,
         assigns <- Map.put(assigns, :tags, tags) do
      PageView.render("index.html", assigns)
    end
  end
end
