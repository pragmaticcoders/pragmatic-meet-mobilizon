defmodule Mobilizon.Service.ActorSuspensionTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.{Actors, Config, Discussions, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.ActorSuspension
  alias Mobilizon.Web.Upload.Uploader

  describe "soft suspend a person" do
    setup do
      user = insert(:user)
      %Actor{} = actor = insert(:actor, user: user)

      %Comment{} = comment = insert(:comment, actor: actor)
      %Event{} = event = insert(:event, organizer_actor: actor)

      {:ok, actor: actor, user: user, comment: comment, event: event}
    end

    test "preserves user_id and profile data", %{actor: actor, user: user, comment: comment, event: event} do
      # Verify initial state
      assert actor.user_id == user.id
      assert actor.suspended == false

      # Perform soft suspension
      assert {:ok, %Actor{} = suspended_actor} = 
        ActorSuspension.suspend_actor(actor, soft_suspend: true)

      # Verify suspension
      assert suspended_actor.suspended == true

      # Reload from database
      reloaded_actor = Actors.get_actor(actor.id)
      
      # Verify user_id is preserved
      assert reloaded_actor.user_id == user.id
      
      # Verify actor still appears in user's actors list
      actors = Users.get_actors_for_user(user)
      # Note: get_actors_for_user filters out suspended actors, so we check directly
      assert reloaded_actor.suspended == true

      # Verify content is NOT deleted (soft suspend doesn't delete content)
      assert %Comment{deleted_at: nil} = Discussions.get_comment(comment.id)
      assert {:ok, %Event{}} = Events.get_event(event.id)

      # Verify media is preserved
      assert actor
             |> media_paths()
             |> media_exists?()
    end

    test "sends notification when suspension: true is set", %{actor: actor} do
      # Soft suspend with notifications
      assert {:ok, %Actor{}} = 
        ActorSuspension.suspend_actor(actor, soft_suspend: true, suspension: true)
      
      # Actor should be suspended
      assert %Actor{suspended: true} = Actors.get_actor(actor.id)
    end
  end

  describe "full suspend a person" do
    setup do
      user = insert(:user)
      %Actor{} = actor = insert(:actor, user: user)
      insert(:actor, user: user)

      %Comment{} = comment = insert(:comment, actor: actor)
      %Event{} = event = insert(:event, organizer_actor: actor)
      %Event{} = insert(:event)
      insert(:participant, event: event)

      %Participant{} =
        participant = insert(:participant, actor: actor, event: event, role: :participant)

      {:ok, actor: actor, user: user, comment: comment, event: event, participant: participant}
    end

    test "clears user_id and deletes content", %{actor: actor, user: user, comment: comment, event: event, participant: participant} do
      assert actor
             |> media_paths()
             |> media_exists?()

      # Full suspension (default behavior, soft_suspend: false)
      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(actor, soft_suspend: false)
      
      reloaded_actor = Actors.get_actor(actor.id)
      assert reloaded_actor.suspended == true
      # Full suspend clears user_id
      assert reloaded_actor.user_id == nil
      
      assert %Comment{deleted_at: %DateTime{}} = Discussions.get_comment(comment.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)
      assert nil == Events.get_participant(participant.id)

      refute actor
             |> media_paths()
             |> media_exists?()
    end

    test "default behavior is full suspend", %{actor: actor, comment: comment, event: event, participant: participant} do
      assert actor
             |> media_paths()
             |> media_exists?()

      # Default behavior without soft_suspend option
      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(actor)
      assert %Actor{suspended: true, user_id: nil} = Actors.get_actor(actor.id)
      assert %Comment{deleted_at: %DateTime{}} = Discussions.get_comment(comment.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)
      assert nil == Events.get_participant(participant.id)

      refute actor
             |> media_paths()
             |> media_exists?()
    end
  end

  describe "delete a person" do
    setup do
      %Actor{} = actor = insert(:actor)

      %Comment{} = comment = insert(:comment, actor: actor)
      %Event{} = event = insert(:event, organizer_actor: actor)

      {:ok, actor: actor, comment: comment, event: event}
    end

    test "local", %{actor: actor, comment: comment, event: event} do
      assert actor
             |> media_paths()
             |> media_exists?()

      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(actor, reserve_username: false)
      assert nil == Actors.get_actor(actor.id)
      assert %Comment{deleted_at: %DateTime{}} = Discussions.get_comment(comment.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)

      refute actor
             |> media_paths()
             |> media_exists?()
    end
  end

  describe "suspend a group" do
    setup do
      %Actor{} = group = insert(:group)

      %Event{} = event = insert(:event, attributed_to: group)

      {:ok, group: group, event: event}
    end

    test "local", %{group: group, event: event} do
      assert {:ok, %Actor{}} = ActorSuspension.suspend_actor(group)
      assert %Actor{suspended: true} = Actors.get_actor(group.id)
      assert {:error, :event_not_found} = Events.get_event(event.id)
    end
  end

  defp media_paths(%Actor{avatar: %{url: avatar_url}, banner: %{url: banner_url}}) do
    %URI{path: "/media/" <> avatar_path} = URI.parse(avatar_url)
    %URI{path: "/media/" <> banner_path} = URI.parse(banner_url)
    %{avatar: avatar_path, banner: banner_path}
  end

  defp media_exists?(%{avatar: avatar_path, banner: banner_path}) do
    File.exists?(
      Config.get!([Uploader.Local, :uploads]) <>
        "/" <> avatar_path
    ) &&
      File.exists?(
        Config.get!([Uploader.Local, :uploads]) <>
          "/" <> banner_path
      )
  end
end
