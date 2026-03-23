defmodule Mobilizon.Repo.Migrations.AddPendingGroupApprovalToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:pending_group_approval, :boolean, null: false, default: false)
    end
  end
end
