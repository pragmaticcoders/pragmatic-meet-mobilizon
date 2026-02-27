defmodule Mobilizon.Storage.Repo.Migrations.CreateGroupInvitationTokens do
  use Ecto.Migration

  def change do
    create table(:group_invitation_tokens, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:token, :string, null: false)
      add(:group_id, references(:actors, on_delete: :delete_all), null: false)
      add(:email, :string, null: false)
      add(:invited_by_id, references(:actors, on_delete: :nilify_all), null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:used_at, :utc_datetime)
      add(:for_new_user, :boolean, null: false, default: false)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:group_invitation_tokens, [:token])
    create index(:group_invitation_tokens, [:group_id])
    create index(:group_invitation_tokens, [:email])
  end
end
