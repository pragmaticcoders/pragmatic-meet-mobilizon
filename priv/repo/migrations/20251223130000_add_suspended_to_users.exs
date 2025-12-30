defmodule Mobilizon.Storage.Repo.Migrations.AddSuspendedToUsers do
  @moduledoc """
  Add suspended field to users table for temporary account suspension.
  
  - suspended: true = Account is temporarily suspended (admin can unsuspend)
  - disabled: true = Account is permanently deleted (email reserved)
  """
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:suspended, :boolean, default: false, null: false)
    end

    # Create index for efficient queries on suspended users
    create(index(:users, [:suspended]))
  end
end





