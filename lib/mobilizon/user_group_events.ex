defmodule Mobilizon.UserGroupEvents do
  @moduledoc """
  Provide events from groups that a user is associated with (follows or is a member of).
  This includes both followed groups and groups where the user is a member/admin.
  """

  import Ecto.Query
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Page

  @spec user_group_events(
          integer() | String.t(),
          DateTime.t() | nil,
          integer() | nil,
          integer() | nil
        ) :: Page.t(Event.t())
  def user_group_events(user_id, after_datetime \\ nil, page \\ nil, limit \\ nil) do
    Event
    |> distinct([e], [e.begins_on, e.id])
    |> join(:inner, [e], g in Actor, on: e.attributed_to_id == g.id and g.type == :Group)
    |> join(:left, [_e, g], f in Follower, on: g.id == f.target_actor_id)
    |> join(:left, [_e, g], m in Member, on: g.id == m.parent_id)
    |> join(:inner, [_e, _g, f, m], a in Actor,
      on: a.id == f.actor_id or a.id == m.actor_id
    )
    |> add_after_datetime_filter(after_datetime)
    |> where(
      [_e, _g, f, m, a],
      (f.approved or m.role in ^[:member, :moderator, :administrator, :creator]) and
        a.user_id == ^user_id
    )
    |> preload([
      :organizer_actor,
      :attributed_to,
      :tags,
      :physical_address,
      :picture
    ])
    |> select([e, g, _f, _m, a], [
      e,
      g,
      a
    ])
    |> Page.build_page(page, limit)
  end

  @spec add_after_datetime_filter(Ecto.Query.t(), DateTime.t() | nil) :: Ecto.Query.t()
  defp add_after_datetime_filter(query, nil),
    do: where(query, [e], e.begins_on > ^DateTime.utc_now())

  defp add_after_datetime_filter(query, %DateTime{} = datetime),
    do: where(query, [e], e.begins_on > ^datetime)
end

