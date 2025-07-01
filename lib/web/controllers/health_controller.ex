defmodule Mobilizon.Web.HealthController do
  @moduledoc """
  Health check controller for monitoring and load balancers
  """

  use Mobilizon.Web, :controller
  alias Mobilizon.Storage.Repo
  require Logger

  @doc """
  Simple health check endpoint that returns 200 OK if the application is running
  """
  @spec health(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def health(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> json(%{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: Mobilizon.Config.instance_version()
    })
  end

  @doc """
  Detailed health check that includes database connectivity
  """
  @spec health_detailed(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def health_detailed(conn, _params) do
    db_status = check_database_health()

    status = if db_status == :ok, do: "healthy", else: "unhealthy"
    http_status = if db_status == :ok, do: 200, else: 503

    conn
    |> put_status(http_status)
    |> put_resp_content_type("application/json")
    |> json(%{
      status: status,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: Mobilizon.Config.instance_version(),
      checks: %{
        database: db_status
      }
    })
  end

  @spec check_database_health :: :ok | :error
  defp check_database_health do
    try do
      case Repo.query("SELECT 1") do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end
    rescue
      _ -> :error
    end
  end
end 