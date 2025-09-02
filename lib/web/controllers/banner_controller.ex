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

    conn
    |> put_layout(false)
    |> render("iframe.html", theme: theme)
  end
end
