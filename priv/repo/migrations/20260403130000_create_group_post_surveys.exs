defmodule Mobilizon.Storage.Repo.Migrations.CreateGroupPostSurveys do
  use Ecto.Migration

  def change do
    create table(:group_post_surveys) do
      add(:uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:title, :string, null: false, default: "")
      add(:description, :text)
      add(:schema, :map, null: false, default: %{})
      add(:status, :string, null: false, default: "draft")
      add(:context_id, :string, null: false, default: "")
      add(:group_id, references(:actors, on_delete: :delete_all), null: false)
      timestamps()
    end

    create(index(:group_post_surveys, [:group_id]))
    create(index(:group_post_surveys, [:context_id], unique: true))
  end
end
