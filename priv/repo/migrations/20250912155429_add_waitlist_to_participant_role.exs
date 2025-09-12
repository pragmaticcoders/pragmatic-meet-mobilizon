defmodule Mobilizon.Storage.Repo.Migrations.AddWaitlistToParticipantRole do
  use Ecto.Migration
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Events.Participant
  alias Mobilizon.Events.ParticipantRole
  import Ecto.Query

  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute(
      "ALTER TYPE #{ParticipantRole.type()} ADD VALUE IF NOT EXISTS 'waitlist'"
    )
  end

  def down do
    Participant
    |> where(role: "waitlist")
    |> Repo.delete_all()
  end
end
