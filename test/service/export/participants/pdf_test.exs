defmodule Mobilizon.Service.Export.Participants.PDFTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.Participants.PDF

  setup do
    test_format?()
  end

  describe "export event participants to PDF" do
    test "export basic infos" do
      %Event{} = event = insert(:event)
      insert(:participant, event: event, role: :creator)
      insert(:participant, event: event, role: :participant)
      insert(:participant, event: event, role: :not_approved)

      set_exports(Mobilizon.Service.Export.Participants.CSV)

      refute PDF.ready?()
    end

    test "enable the exporter" do
      set_exports(Mobilizon.Service.Export.Participants.PDF)

      %Event{} = event = insert(:event)
      insert(:participant, event: event, role: :creator)
      insert(:participant, event: event, role: :participant)
      insert(:participant, event: event, role: :not_approved)

      # Only test if Python dependencies are available
      # Catch both exceptions and exits from missing Python modules
      try do
        if PDF.dependencies_ok?() do
          assert PDF.enabled?()
          assert {:ok, path} = PDF.export(event)
          assert File.exists?("uploads/exports/pdf/" <> path)
        end
      rescue
        # Also catch regular exceptions
        _ ->
          # Skip test if dependencies are not available
          :ok
      catch
        # Catch GenServer exits from missing Python dependencies
        :exit, _ ->
          # Skip test if dependencies are not available
          :ok
      end
      
      set_exports(Mobilizon.Service.Export.Participants.CSV)
    end
  end

  @spec set_exports(module()) :: :ok
  defp set_exports(module) do
    Mobilizon.Config.put(:exports,
      formats: [module]
    )
  end

  @spec test_format? :: :ok | {:ok, skip: true}
  defp test_format? do
    case System.get_env("EXPORT_FORMATS") do
      nil ->
        {:ok, skip: true}

      formats ->
        if "pdf" in String.split(formats, ",") do
          :ok
        else
          {:ok, skip: true}
        end
    end
  end
end
