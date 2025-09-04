defmodule Mobilizon.Repo.Migrations.RemoveCustomUrlFromEvents do
  use Ecto.Migration

  def up do
    alter table("events") do
      remove(:custom_url)
    end
  end

  def down do
    alter table("events") do
      add(:custom_url, :string, null: true)
    end
  end
end
