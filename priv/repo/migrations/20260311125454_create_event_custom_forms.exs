defmodule Mobilizon.Storage.Repo.Migrations.CreateEventCustomForms do
  use Ecto.Migration

  def change do
    create table(:event_custom_forms) do
      add(:event_id, references(:events, on_delete: :delete_all), null: false)
      add(:fields, :jsonb, default: "[]", null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:event_custom_forms, [:event_id]))
  end
end
