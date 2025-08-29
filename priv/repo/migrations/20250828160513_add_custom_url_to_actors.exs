defmodule Mobilizon.Repo.Migrations.AddCustomUrlToActors do
  use Ecto.Migration

  def up do
    alter table("actors") do
      add(:custom_url, :string, null: true)
    end
  end

  def down do
    alter table("actors") do
      remove(:custom_url)
    end
  end
end
