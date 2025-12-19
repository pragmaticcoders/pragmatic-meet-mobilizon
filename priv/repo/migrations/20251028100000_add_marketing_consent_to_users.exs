defmodule Mobilizon.Storage.Repo.Migrations.AddMarketingConsentToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:marketing_consent, :boolean, default: false, null: false)
      add(:marketing_consent_updated_at, :utc_datetime, null: true)
    end
  end
end

