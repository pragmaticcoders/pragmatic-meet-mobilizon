defmodule Mobilizon.Storage.Repo.Migrations.CreateEventPostSurveys do
  use Ecto.Migration

  def change do
    create table(:event_post_surveys) do
      add(:uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:title, :string, null: false, default: "")
      add(:schema, :map, null: false, default: %{})
      add(:status, :string, null: false, default: "draft")
      add(:context_id, :string, null: false, default: "")
      add(:event_id, references(:events, on_delete: :delete_all), null: false)
      timestamps()
    end

    create(index(:event_post_surveys, [:event_id]))
    create(index(:event_post_surveys, [:context_id], unique: true))
  end
end
