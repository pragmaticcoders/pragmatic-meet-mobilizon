defmodule Mobilizon.Invitations.GroupInvitationToken do
  @moduledoc """
  Schema for one-time, time-limited group invitation tokens sent by email.

  Used when inviting someone by email (existing or new user). Token is embedded
  in the invitation link; when used, the recipient is added to the group
  (or redirected to register first if they don't have an account).
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "group_invitation_tokens" do
    field(:token, :string)
    field(:email, :string)
    field(:expires_at, :utc_datetime)
    field(:used_at, :utc_datetime)
    field(:for_new_user, :boolean, default: false)

    belongs_to(:group, Actor)
    belongs_to(:invited_by, Actor)

    timestamps(type: :utc_datetime_usec)
  end

  @required [:token, :email, :expires_at, :for_new_user, :group_id, :invited_by_id]
  @optional [:used_at]

  @doc false
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:token)
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:invited_by_id)
  end
end
