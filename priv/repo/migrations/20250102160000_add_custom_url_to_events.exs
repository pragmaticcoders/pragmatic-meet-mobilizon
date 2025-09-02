defmodule Mobilizon.Repo.Migrations.AddCustomUrlToEvents do
  use Ecto.Migration

  def up do
    alter table("events") do
      add(:custom_url, :string, null: true)
    end
  end

  def down do
    alter table("events") do
      remove(:custom_url)
    end
  end
end
