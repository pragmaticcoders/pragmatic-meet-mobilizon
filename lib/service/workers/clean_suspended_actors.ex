defmodule Mobilizon.Service.Workers.CleanSuspendedActors do
  @moduledoc """
  Worker to clean suspended actors.

  DEPRECATED: This worker is disabled. Suspended actors are no longer automatically
  cleaned up. Administrators can now permanently delete actors through the admin UI
  when needed. This preserves suspended actor data until an explicit deletion is requested.
  """

  use Oban.Worker, queue: "background"
  require Logger

  @impl Oban.Worker
  def perform(%Job{}) do
    Logger.info(
      "CleanSuspendedActors worker is disabled. " <>
        "Suspended actors are preserved until explicitly deleted by administrators."
    )

    :ok
  end
end
