defmodule Mobilizon.Storage.Repo.Migrations.FixBrokenActorUserRelationships do
  @moduledoc """
  Fix broken actor-user relationships where user_id is NULL but a user has the actor as their default_actor.
  
  This can happen when actors were suspended using the old delete_changeset which cleared user_id.
  In single-profile systems, this breaks the user-actor relationship and prevents profiles from being listed.
  """
  use Ecto.Migration

  def up do
    # Find all actors where:
    # - user_id is NULL
    # - A user has them as their default_actor_id
    # - Actor type is 'Person'
    # And update the actor's user_id to match the user's id
    execute("""
    UPDATE actors 
    SET user_id = users.id
    FROM users 
    WHERE users.default_actor_id = actors.id 
      AND actors.user_id IS NULL
      AND actors.type = 'Person'
    """)
  end

  def down do
    # No rollback - we don't want to break relationships again
    # This is a data fix migration, not a schema change
    :ok
  end
end





