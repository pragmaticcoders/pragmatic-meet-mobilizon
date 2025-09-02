defmodule Mobilizon.Web.BannerController do
  @moduledoc """
  Controller for serving embeddable banner iframes
  """
  use Mobilizon.Web, :controller

  @doc """
  Renders an embeddable banner iframe
  """
  def iframe(conn, params) do
    theme = Map.get(params, "theme", "light")
    group = Map.get(params, "group", nil)

    conn
    |> put_layout(false)
    |> render("iframe.html", theme: theme, group: group)
  end
end
