defmodule Mobilizon.Repo.Migrations.AddWaitlistToParticipantStats do
  use Ecto.Migration

  def up do
    # Update all events that don't have the waitlist field in participant_stats
    # Set it to 0 if missing, or calculate the actual count from participants table
    execute("""
    UPDATE events
    SET participant_stats = participant_stats || '{"waitlist": 0}'::jsonb
    WHERE participant_stats IS NOT NULL
      AND NOT (participant_stats ? 'waitlist')
    """)

    # Now update with actual waitlist counts from participants table
    execute("""
    UPDATE events e
    SET participant_stats = jsonb_set(
      e.participant_stats,
      '{waitlist}',
      (
        SELECT COALESCE(COUNT(*)::text, '0')::jsonb
        FROM participants p
        WHERE p.event_id = e.id AND p.role = 'waitlist'
      )
    )
    WHERE e.participant_stats IS NOT NULL
    """)
  end

  def down do
    # Remove the waitlist field from participant_stats
    execute("""
    UPDATE events
    SET participant_stats = participant_stats - 'waitlist'
    WHERE participant_stats IS NOT NULL
      AND participant_stats ? 'waitlist'
    """)
  end
end

