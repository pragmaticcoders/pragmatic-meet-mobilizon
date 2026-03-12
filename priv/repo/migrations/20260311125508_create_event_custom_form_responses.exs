defmodule Mobilizon.Storage.Repo.Migrations.CreateEventCustomFormResponses do
  use Ecto.Migration

  def change do
    create table(:event_custom_form_responses) do
      add(:event_id, references(:events, on_delete: :delete_all), null: false)
      add(:participant_id, references(:participants, type: :binary_id, on_delete: :delete_all), null: false)
      add(:answers, :jsonb, default: "{}", null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:event_custom_form_responses, [:event_id, :participant_id]))
  end
end
