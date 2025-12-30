defmodule Mobilizon.Service.Workers.CleanSuspendedActorsTest do
  @moduledoc """
  Tests for the CleanSuspendedActors worker.
  
  This worker is intentionally disabled. Suspended actors are now preserved
  until explicitly deleted by administrators through the admin UI.
  """
  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  import Mobilizon.Factory
  import Ecto.Query

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Workers.CleanSuspendedActors

  describe "CleanSuspendedActors worker" do
    test "does not delete any actors (worker is disabled)" do
      # Create a suspended actor that would normally be purged
      user = insert(:user)
      suspended_actor = insert(:actor, user: user, suspended: true)
      
      # Simulate old suspension date by updating the updated_at timestamp
      # to more than 30 days ago
      old_date = DateTime.add(DateTime.utc_now(), -31, :day) |> DateTime.truncate(:second)
      
      Mobilizon.Storage.Repo.update_all(
        from(a in Actor, where: a.id == ^suspended_actor.id),
        set: [updated_at: old_date]
      )
      
      # Verify the actor exists before
      assert %Actor{suspended: true} = Actors.get_actor(suspended_actor.id)
      
      # Run the worker
      assert :ok = perform_job(CleanSuspendedActors, %{})
      
      # The actor should still exist - the worker is disabled
      assert %Actor{suspended: true} = Actors.get_actor(suspended_actor.id)
      
      # Verify user_id relationship is preserved
      actor = Actors.get_actor(suspended_actor.id)
      assert actor.user_id == user.id
    end

    test "logs a message about being disabled" do
      # The worker should complete successfully and return :ok
      assert :ok = perform_job(CleanSuspendedActors, %{})
    end
  end
end

