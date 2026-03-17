defmodule Mobilizon.Web.WebhookController do
  @moduledoc """
  Webhook endpoints for external service integration.
  """

  use Mobilizon.Web, :controller

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.GraphQL.API.Participations
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Auth.Guardian

  require Logger

  @doc """
  Join an event on behalf of an authenticated user.

  Accepts:
    - `auth_token` – the user's JWT access token
    - `event_id`   – the ID of the event to join

  Returns `200 %{status: "ok"}` on success (including when already a participant),
  or `400 %{status: "error", message: ...}` on failure.
  """
  @spec user_participate_join(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def user_participate_join(conn, %{"auth_token" => auth_token, "event_id" => event_id}) do
    with {:token, {:ok, claims}} <- {:token, Guardian.decode_and_verify(auth_token)},
         {:user, {:ok, %User{default_actor: actor} = _user}} <-
           {:user, Guardian.resource_from_claims(claims)},
         {:actor, true} <- {:actor, not is_nil(actor)},
         {:event, %Event{} = event} <- {:event, Events.get_event_by_uuid_with_preload(event_id)} do
      case Participations.join(event, actor) do
        {:ok, _activity, _participant} ->
          json(conn, %{status: "ok"})

        {:ok, _activity, _participant, :waitlist} ->
          json(conn, %{status: "ok"})

        {:error, :already_participant} ->
          json(conn, %{status: "ok"})

        {:error, reason} ->
          Logger.warning("webhook user_participate_join failed: #{inspect(reason)}")

          conn
          |> put_status(:bad_request)
          |> json(%{status: "error", message: inspect(reason)})
      end
    else
      {:token, {:error, reason}} ->
        Logger.warning("webhook user_participate_join: invalid token – #{inspect(reason)}")

        conn
        |> put_status(:unauthorized)
        |> json(%{status: "error", message: "Invalid or expired auth token"})

      {:user, {:error, reason}} ->
        Logger.warning("webhook user_participate_join: user not found – #{inspect(reason)}")

        conn
        |> put_status(:unauthorized)
        |> json(%{status: "error", message: "User not found"})

      {:actor, false} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "User has no default actor"})

      {:event, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "Event not found"})
    end
  end

  def user_participate_join(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{status: "error", message: "Missing required parameters: auth_token, event_id"})
  end
end
