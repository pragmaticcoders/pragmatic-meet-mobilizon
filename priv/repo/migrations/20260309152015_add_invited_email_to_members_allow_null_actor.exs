defmodule Mobilizon.Repo.Migrations.AddInvitedEmailToMembersAllowNullActor do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add(:invited_email, :string)
    end

    # Allow actor_id to be null for members invited by email (not yet on platform)
    execute("ALTER TABLE members ALTER COLUMN actor_id DROP NOT NULL")
  end

  def down do
    # Remove any members that have null actor_id before re-adding NOT NULL
    execute("DELETE FROM members WHERE actor_id IS NULL")

    alter table(:members) do
      remove(:invited_email)
    end

    execute("ALTER TABLE members ALTER COLUMN actor_id SET NOT NULL")
  end
end
