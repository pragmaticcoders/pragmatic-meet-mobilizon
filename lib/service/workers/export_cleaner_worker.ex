defmodule Mobilizon.Service.Workers.ExportCleanerWorker do
  @moduledoc """
  Worker to clean exports
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Config

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Job{}) do
    export_config = Application.get_env(:mobilizon, :exports)
    formats = Keyword.get(export_config, :formats, [])
    Enum.each(formats, & &1.clean_exports())
  end
end
