defmodule Mobilizon.GraphQL.API.ParticipationsWaitlistTest do
  @moduledoc """
  Test waitlist auto-promotion functionality, specifically FIFO ordering.
  """

  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events
  alias Mobilizon.GraphQL.API.Participations
  alias Mobilizon.Storage.Repo

  describe "promote_from_waitlist_if_needed/1" do
    test "promotes waitlist participants in FIFO order (oldest first)" do
      # Create an event with capacity of 2
      event =
        insert(:event,
          options: %{
            maximum_attendee_capacity: 2,
            enable_waitlist: true,
            waitlist_auto_promote: true
          }
        )

      # Create actors
      organizer = insert(:actor)
      participant1 = insert(:actor)
      participant2 = insert(:actor)
      waitlist_user1 = insert(:actor)
      waitlist_user2 = insert(:actor)
      waitlist_user3 = insert(:actor)

      # Set organizer (takes 1 spot but doesn't count towards capacity)
      insert(:participant, event: event, actor: organizer, role: :creator)

      # Fill the event to capacity (2 spots)
      p1 =
        insert(:participant,
          event: event,
          actor: participant1,
          role: :participant,
          inserted_at: ~U[2024-01-01 10:00:00Z]
        )

      insert(:participant,
        event: event,
        actor: participant2,
        role: :participant,
        inserted_at: ~U[2024-01-01 10:05:00Z]
      )

      # Add 3 users to waitlist at different times
      w1 =
        insert(:participant,
          event: event,
          actor: waitlist_user1,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 11:00:00Z]
        )

      w2 =
        insert(:participant,
          event: event,
          actor: waitlist_user2,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 12:00:00Z]
        )

      w3 =
        insert(:participant,
          event: event,
          actor: waitlist_user3,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 13:00:00Z]
        )

      # Verify initial state: 2 participants + 3 on waitlist
      assert Events.count_participants_by_role(event.id, [:participant]) == 2
      assert Events.count_participants_by_role(event.id, [:waitlist]) == 3

      # Remove one participant to create 1 available spot
      # Use Repo.delete! for simpler test deletion (bypasses business logic)
      Repo.delete!(p1)
      
      # Verify deletion worked
      assert Events.count_participant_participants(event.id) == 1
      assert Events.count_participants_by_role(event.id, [:participant]) == 1

      # Trigger auto-promotion (this runs synchronously in tests)
      Participations.promote_from_waitlist_if_needed(event.id)

      # Small delay to ensure all database operations complete
      Process.sleep(500)

      # Verify that the OLDEST waitlist member (w1) was promoted
      promoted = Events.get_participant(w1.id)
      assert promoted.role == :participant

      # Verify that w2 and w3 are still on waitlist
      still_waitlist2 = Events.get_participant(w2.id)
      assert still_waitlist2.role == :waitlist

      still_waitlist3 = Events.get_participant(w3.id)
      assert still_waitlist3.role == :waitlist

      # Verify final counts
      assert Events.count_participants_by_role(event.id, [:participant]) == 2
      assert Events.count_participants_by_role(event.id, [:waitlist]) == 2
    end

    test "promotes multiple waitlist participants when multiple spots available, in FIFO order" do
      # Create an event with capacity of 3
      event =
        insert(:event,
          options: %{
            maximum_attendee_capacity: 3,
            enable_waitlist: true,
            waitlist_auto_promote: true
          }
        )

      organizer = insert(:actor)
      participant1 = insert(:actor)
      waitlist_user1 = insert(:actor)
      waitlist_user2 = insert(:actor)
      waitlist_user3 = insert(:actor)
      waitlist_user4 = insert(:actor)

      # Set organizer
      insert(:participant, event: event, actor: organizer, role: :creator)

      # Fill the event to capacity (3 spots) - add 3 participants
      participant2 = insert(:actor)
      participant3 = insert(:actor)
      
      p1 =
        insert(:participant,
          event: event,
          actor: participant1,
          role: :participant,
          inserted_at: ~U[2024-01-01 10:00:00Z]
        )
      
      p2 =
        insert(:participant,
          event: event,
          actor: participant2,
          role: :participant,
          inserted_at: ~U[2024-01-01 10:01:00Z]
        )
      
      insert(:participant,
        event: event,
        actor: participant3,
        role: :participant,
        inserted_at: ~U[2024-01-01 10:02:00Z]
      )

      # Add 4 users to waitlist at different times (oldest to newest)
      w1 =
        insert(:participant,
          event: event,
          actor: waitlist_user1,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 11:00:00Z]
        )

      w2 =
        insert(:participant,
          event: event,
          actor: waitlist_user2,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 12:00:00Z]
        )

      w3 =
        insert(:participant,
          event: event,
          actor: waitlist_user3,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 13:00:00Z]
        )

      w4 =
        insert(:participant,
          event: event,
          actor: waitlist_user4,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 14:00:00Z]
        )

      # Remove 2 participants to create 2 available spots (3 capacity - 1 remaining = 2 spots)
      # Use Repo.delete! for simpler test deletion (bypasses business logic)
      Repo.delete!(p1)
      Repo.delete!(p2)
      
      # Verify deletions worked
      assert Events.count_participant_participants(event.id) == 1
      assert Events.count_participants_by_role(event.id, [:participant]) == 1

      # Trigger auto-promotion - should promote 2 oldest waitlist members
      Participations.promote_from_waitlist_if_needed(event.id)

      # Small delay to ensure all database operations complete
      Process.sleep(500)

      # Verify that the 2 OLDEST waitlist members (w1 and w2) were promoted
      promoted1 = Events.get_participant(w1.id)
      assert promoted1.role == :participant

      promoted2 = Events.get_participant(w2.id)
      assert promoted2.role == :participant

      # Verify that w3 and w4 are still on waitlist
      still_waitlist3 = Events.get_participant(w3.id)
      assert still_waitlist3.role == :waitlist

      still_waitlist4 = Events.get_participant(w4.id)
      assert still_waitlist4.role == :waitlist

      # Verify final counts: should have 3 participants (1 original + 2 promoted) and 2 on waitlist
      assert Events.count_participants_by_role(event.id, [:participant]) == 3
      assert Events.count_participants_by_role(event.id, [:waitlist]) == 2
    end

    test "list_participants_for_event returns waitlist in FIFO order" do
      event =
        insert(:event,
          options: %{
            maximum_attendee_capacity: 1,
            enable_waitlist: true
          }
        )

      # Add 5 users to waitlist at different times
      w1_actor = insert(:actor)
      w2_actor = insert(:actor)
      w3_actor = insert(:actor)
      w4_actor = insert(:actor)
      w5_actor = insert(:actor)

      w1 =
        insert(:participant,
          event: event,
          actor: w1_actor,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 10:00:00Z]
        )

      w2 =
        insert(:participant,
          event: event,
          actor: w2_actor,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 11:00:00Z]
        )

      w3 =
        insert(:participant,
          event: event,
          actor: w3_actor,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 12:00:00Z]
        )

      w4 =
        insert(:participant,
          event: event,
          actor: w4_actor,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 13:00:00Z]
        )

      w5 =
        insert(:participant,
          event: event,
          actor: w5_actor,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 14:00:00Z]
        )

      # Get waitlist participants
      %{elements: waitlist_participants} =
        Events.list_participants_for_event(event.id, [:waitlist], 1, 10)

      # Verify they are returned in FIFO order (oldest first)
      assert length(waitlist_participants) == 5
      assert Enum.at(waitlist_participants, 0).id == w1.id
      assert Enum.at(waitlist_participants, 1).id == w2.id
      assert Enum.at(waitlist_participants, 2).id == w3.id
      assert Enum.at(waitlist_participants, 3).id == w4.id
      assert Enum.at(waitlist_participants, 4).id == w5.id
    end

    test "does not auto-promote when waitlist_only is enabled" do
      # Create an event with waitlist_only enabled - auto_promote should be ignored
      event =
        insert(:event,
          options: %{
            maximum_attendee_capacity: 10,
            enable_waitlist: true,
            waitlist_only: true,
            waitlist_auto_promote: true
          }
        )

      organizer = insert(:actor)
      waitlist_user = insert(:actor)

      # Set organizer
      insert(:participant, event: event, actor: organizer, role: :creator)

      # Add user to waitlist
      w1 =
        insert(:participant,
          event: event,
          actor: waitlist_user,
          role: :waitlist,
          inserted_at: ~U[2024-01-01 11:00:00Z]
        )

      # Verify initial state
      assert Events.count_participants_by_role(event.id, [:waitlist]) == 1
      assert Events.count_participants_by_role(event.id, [:participant]) == 0

      # Try to trigger auto-promotion - should NOT promote because waitlist_only is enabled
      Participations.promote_from_waitlist_if_needed(event.id)

      # Small delay
      Process.sleep(100)

      # Verify participant is still on waitlist (not promoted)
      still_waitlist = Events.get_participant(w1.id)
      assert still_waitlist.role == :waitlist

      # Verify counts unchanged
      assert Events.count_participants_by_role(event.id, [:waitlist]) == 1
      assert Events.count_participants_by_role(event.id, [:participant]) == 0
    end

    test "allows manual promotion in waitlist_only mode" do
      # Create an event with waitlist_only enabled
      event =
        insert(:event,
          options: %{
            maximum_attendee_capacity: 10,
            enable_waitlist: true,
            waitlist_only: true
          }
        )

      waitlist_user = insert(:actor)

      # Add user to waitlist
      w1 =
        insert(:participant,
          event: event,
          actor: waitlist_user,
          role: :waitlist
        )

      # Verify initial state
      assert Events.get_participant(w1.id).role == :waitlist

      # Manually promote the participant (simulating admin action)
      {:ok, promoted} = Events.update_participant(w1, %{role: :participant})

      # Verify promotion worked
      assert promoted.role == :participant
      assert Events.count_participants_by_role(event.id, [:participant]) == 1
      assert Events.count_participants_by_role(event.id, [:waitlist]) == 0
    end
  end

  describe "waitlist_only mode" do
    test "waitlist_only requires enable_waitlist to be true to have effect" do
      # Create event with waitlist_only but enable_waitlist false
      # In this case, waitlist_only should have no effect
      event =
        insert(:event,
          options: %{
            maximum_attendee_capacity: 10,
            enable_waitlist: false,
            waitlist_only: true,
            waitlist_auto_promote: true
          }
        )

      organizer = insert(:actor)
      waitlist_user = insert(:actor)

      # Set organizer
      insert(:participant, event: event, actor: organizer, role: :creator)

      # Add user to waitlist manually
      w1 =
        insert(:participant,
          event: event,
          actor: waitlist_user,
          role: :waitlist
        )

      # Verify user is on waitlist
      assert Events.get_participant(w1.id).role == :waitlist

      # Try to trigger auto-promotion
      # Since enable_waitlist is false, the promotion should be skipped entirely
      Participations.promote_from_waitlist_if_needed(event.id)

      Process.sleep(100)

      # User should still be on waitlist because waitlist is not enabled
      assert Events.get_participant(w1.id).role == :waitlist
    end
  end
end

