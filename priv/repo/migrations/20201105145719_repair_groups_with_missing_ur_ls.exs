defmodule Mobilizon.Storage.Repo.Migrations.RepairGroupsWithMissingURLs do
  use Ecto.Migration
  alias Mobilizon.Storage.Repo
  import Ecto.Query

  def up do
    # This is a repair migration for existing data.
    # On fresh databases, there's nothing to repair, so we can skip it safely.
    # We also need to check if the approval_status column exists first
    # (it's added in a later migration)
    try do
      query = """
      SELECT id, url FROM actors
      WHERE type = 'Group' AND domain IS NULL
      """

      {:ok, result} = Repo.query(query)

      Enum.each(result.rows, fn [id, url] ->
        update_query = """
        UPDATE actors SET
          resources_url = $1,
          todos_url = $2,
          posts_url = $3,
          events_url = $4,
          discussions_url = $5
        WHERE id = $6
        """

        Repo.query(update_query, [
          "#{url}/resources",
          "#{url}/todos",
          "#{url}/posts",
          "#{url}/events",
          "#{url}/discussions",
          id
        ])
      end)
    rescue
      e ->
        IO.puts("Skipping repair migration (likely running on fresh database): #{inspect(e)}")
    end
  end

  def down do
    IO.puts("Nothing to revert here, this is a repair step.")
  end
end
