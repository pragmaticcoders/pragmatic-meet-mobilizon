defmodule Mobilizon.Storage.Repo.Migrations.AddLocationHintToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add(:location_hint, :text)
    end
  end
end
