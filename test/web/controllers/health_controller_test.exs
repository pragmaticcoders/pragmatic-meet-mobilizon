defmodule Mobilizon.Web.HealthControllerTest do
  use Mobilizon.Web.ConnCase

  test "GET /health returns 200 OK", %{conn: conn} do
    conn = get(conn, "/health")
    response = json_response(conn, 200)

    assert response["status"] == "ok"
    assert is_binary(response["timestamp"])
    assert is_binary(response["version"])
  end

  test "GET /health/detailed returns health status with database check", %{conn: conn} do
    conn = get(conn, "/health/detailed")
    response = json_response(conn, 200)

    assert response["status"] == "healthy"
    assert is_binary(response["timestamp"])
    assert is_binary(response["version"])
    assert response["checks"]["database"] == :ok
  end
end 