defmodule Mobilizon.Storage.Repo.Migrations.CreateEventRegistrationQuestions do
  use Ecto.Migration

  def change do
    create table(:event_registration_questions) do
      add(:event_id, references(:events, on_delete: :delete_all), null: false)
      add(:position, :integer, null: false, default: 0)
      add(:question_type, :string, null: false)
      add(:title, :string, null: false)
      add(:required, :boolean, null: false, default: false)

      timestamps(type: :utc_datetime)
    end

    create(index(:event_registration_questions, [:event_id]))

    create table(:event_registration_question_options) do
      add(:question_id, references(:event_registration_questions, on_delete: :delete_all),
        null: false
      )
      add(:position, :integer, null: false, default: 0)
      add(:label, :string, null: false)

      timestamps(type: :utc_datetime)
    end

    create(index(:event_registration_question_options, [:question_id]))

    create table(:participant_registration_answers) do
      add(:participant_id, references(:participants, on_delete: :delete_all, type: :uuid),
        null: false
      )
      add(:question_id, references(:event_registration_questions, on_delete: :delete_all),
        null: false
      )
      add(:value, :text, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:participant_registration_answers, [:participant_id, :question_id]))
    create(index(:participant_registration_answers, [:participant_id]))
    create(index(:participant_registration_answers, [:question_id]))
  end
end
