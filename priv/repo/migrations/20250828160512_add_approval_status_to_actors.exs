defmodule Mobilizon.Repo.Migrations.AddApprovalStatusToActors do
  use Ecto.Migration

  def up do
    # First, create the approval status type
    execute("CREATE TYPE actor_approval_status AS ENUM ('pending_approval', 'approved', 'rejected')")

    # Add the approval_status column to actors table with default 'approved'
    alter table("actors") do
      add(:approval_status, :actor_approval_status, default: fragment("'approved'::actor_approval_status"), null: false)
    end

    # Keep all existing groups as approved so they remain functional
    # Only new groups created after this migration will start as pending_approval
    execute("""
    UPDATE actors 
    SET approval_status = 'approved' 
    WHERE type = 'Group'
    """)
  end

  def down do
    alter table("actors") do
      remove(:approval_status)
    end

    execute("DROP TYPE IF EXISTS actor_approval_status")
  end
end
