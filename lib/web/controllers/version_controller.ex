defmodule Mobilizon.Web.VersionController do
  @moduledoc """
  Exposes the build identity of the running release as JSON.

  The frontend polls this endpoint to detect that a new version has been
  deployed without having to reload the SPA. It must never be cached by
  intermediate proxies — the whole point is to bypass every cache layer
  on the way and ask the origin "what version are you running right now?".

  The SHA and build-time are read from the same env vars the Vite build
  receives (`VITE_GIT_COMMIT` / `VITE_BUILD_TIME`), so the value here is
  guaranteed to match `__GIT_COMMIT__` baked into the JS bundle that
  was built with the same env. We read them at **runtime** rather than
  compile-time on purpose: `make cache-deploy SHA=…` should be able to
  flip the reported commit by simply restarting the container, without
  having to bust the BEAM module cache. The performance cost of two
  `System.get_env/1` calls per /version.json request is negligible —
  the SPA polls this once a minute per tab.
  """

  use Mobilizon.Web, :controller

  @spec show(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def show(conn, _params) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate")
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_content_type("application/json")
    |> json(%{
      version: Application.spec(:mobilizon, :vsn) |> to_string(),
      commit: commit(),
      build_time: build_time()
    })
  end

  # Slice the SHA to 7 chars to match what `vite.config.js` bakes into
  # `__GIT_COMMIT__` on the frontend (`gitCommit.slice(0, 7)`). Without
  # this the SPA would always see a mismatch and trigger pointless SW
  # updates on every poll.
  defp commit do
    (System.get_env("VITE_GIT_COMMIT") || "dev") |> String.slice(0, 7)
  end

  defp build_time do
    System.get_env("VITE_BUILD_TIME") || "unknown"
  end
end
