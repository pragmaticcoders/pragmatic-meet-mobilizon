defmodule Mobilizon.Storage.Repo.Migrations.AddDescriptionToEventPostSurveys do
  use Ecto.Migration

  def change do
    alter table(:event_post_surveys) do
      add(:description, :text, null: true, default: nil)
    end
  end
end
