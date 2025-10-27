defmodule Mobilizon.Storage.Repo.Migrations.QueueRebuildEventSearchWithActors do
  use Ecto.Migration
  import Ecto.Query
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Service.Workers.BuildSearch

  def up do
    # Get all event IDs
    event_ids =
      "events"
      |> select([e], e.id)
      |> Repo.all()

    # Queue rebuild jobs in batches to avoid overwhelming Oban
    event_ids
    |> Enum.chunk_every(250)
    |> Enum.each(fn batch ->
      jobs =
        Enum.map(batch, fn event_id ->
          BuildSearch.new(
            %{"op" => "update_search_event", "event_id" => event_id},
            queue: :search
          )
          |> Oban.Job.to_map()
        end)

      Repo.insert_all("oban_jobs", jobs)
    end)
  end

  def down do
    # Nothing to do - the jobs will just process with the old format
    :ok
  end
end

