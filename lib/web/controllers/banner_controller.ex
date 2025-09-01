defmodule Mobilizon.Web.BannerController do
  @moduledoc """
  Controller to serve iframe banner with logo
  """
  use Mobilizon.Web, :controller

  @spec iframe(Plug.Conn.t(), any) :: Plug.Conn.t()
  def iframe(conn, params) do
    theme = Map.get(params, "theme", "light")

    logo_file =
      case theme do
        "dark" -> "Logo-on-dark.png"
        _ -> "Logo-on-light.png"
      end

    theme_class =
      case theme do
        "dark" -> "theme-dark"
        _ -> "theme-light"
      end

    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> put_resp_header("x-frame-options", "ALLOWALL")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> put_layout(false)
    |> render("iframe.html", logo_file: logo_file, theme_class: theme_class)
  end
end
