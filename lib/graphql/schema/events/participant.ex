defmodule Mobilizon.GraphQL.Schema.Events.ParticipantType do
  @moduledoc """
  Schema representation for Participant.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.GraphQL.Resolvers.Participant

  @desc "Represents a participant to an event"
  object :participant do
    meta(:authorize, :all)
    field(:id, :id, description: "The participation ID")

    field(
      :event,
      :event,
      resolve: dataloader(Events),
      description: "The event which the actor participates in"
    )

    field(
      :actor,
      :actor,
      resolve: dataloader(Actors),
      description: "The actor that participates to the event"
    )

    field(:role, :participant_role_enum, description: "The role of this actor at this event")

    field(:metadata, :participant_metadata,
      description: "The metadata associated to this participant"
    )

    field(:inserted_at, :datetime, description: "The datetime this participant was created")

    field(:waitlist_position, :integer,
      description: "The position in the waitlist (1-based), or null if not on waitlist",
      resolve: &Participant.resolve_waitlist_position/3
    )
  end

  @desc """
  Metadata about a participant
  """
  object :participant_metadata do
    meta(:authorize, :all)

    field(:cancellation_token, :string,
      description: "The eventual token to leave an event when user is anonymous"
    )

    field(:message, :string, description: "The eventual message the participant left")
    field(:locale, :string, description: "The participant's locale")
  end

  @desc """
  A paginated list of participants
  """
  object :paginated_participant_list do
    meta(:authorize, :all)
    field(:elements, list_of(:participant), description: "A list of participants")
    field(:total, :integer, description: "The total number of participants in the list")
  end

  object :participant_export do
    meta(:authorize, :user)
    field(:path, :string, description: "The path to the exported file")
    field(:format, :export_format_enum, description: "The path to the exported file")
  end

  @desc """
  The possible values for a participant role
  """
  enum :participant_role_enum do
    value(:not_approved, description: "The participant has not been approved")
    value(:not_confirmed, description: "The participant has not confirmed their participation")
    value(:participant, description: "The participant is a regular participant")
    value(:moderator, description: "The participant is an event moderator")
    value(:administrator, description: "The participant is an event administrator")
    value(:creator, description: "The participant is an event creator")
    value(:rejected, description: "The participant has been rejected from this event")
    value(:waitlist, description: "The participant is on the waitlist for this event")
  end

  enum :export_format_enum do
    value(:csv, description: "CSV format")
    value(:pdf, description: "PDF format")
    value(:ods, description: "ODS format")
  end

  @desc "Survey gate status for join event"
  enum :survey_status do
    value(:joined, description: "The participant joined successfully")
    value(:survey_required, description: "A survey must be completed before joining")
  end

  @desc "Response from joining an event — may require survey completion first"
  object :join_event_response do
    meta(:authorize, :all)
    field(:status, :survey_status, description: "Whether joined or survey required")
    field(:survey_schema, :json, description: "Survey schema when status is survey_required")
    field(:context_id, :string, description: "Survey context ID when status is survey_required")
    field(:participant, :participant, description: "The joined participant when status is joined")
  end

  @desc "Represents a deleted participant"
  object :deleted_participant do
    meta(:authorize, :all)
    field(:id, :id, description: "The participant ID")
    field(:event, :event, description: "The participant's event")
    field(:actor, :actor, description: "The participant's actor")
  end

  object :participant_mutations do
    @desc "Join an event"
    field :join_event, :join_event_response do
      arg(:event_id, non_null(:id), description: "The event ID that is joined")
      arg(:actor_id, non_null(:id), description: "The actor ID for the participant")
      arg(:email, :string, description: "The anonymous participant's email")
      arg(:message, :string, description: "The anonymous participant's message")
      arg(:locale, :string, description: "The anonymous participant's locale")
      arg(:timezone, :timezone, description: "The anonymous participant's timezone")
      middleware(Rajska.QueryAuthorization, permit: :all, rule: :"write:participation")
      resolve(&Participant.actor_join_event/3)
    end

    @desc "Leave an event"
    field :leave_event, :deleted_participant do
      arg(:event_id, non_null(:id), description: "The event ID the participant left")
      arg(:actor_id, non_null(:id), description: "The actor ID for the participant")
      arg(:token, :string, description: "The anonymous participant participation token")
      middleware(Rajska.QueryAuthorization, permit: :all, rule: :"write:participation")
      resolve(&Participant.actor_leave_event/3)
    end

    @desc "Update a participation"
    field :update_participation, :participant do
      arg(:id, non_null(:id), description: "The participant ID")
      arg(:role, non_null(:participant_role_enum), description: "The participant new role")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Events.Participant,
        rule: :"write:participation"
      )

      resolve(&Participant.update_participation/3)
    end

    @desc "Confirm a participation"
    field :confirm_participation, :participant do
      arg(:confirmation_token, non_null(:string), description: "The participation token")
      middleware(Rajska.QueryAuthorization, permit: :all, rule: :"write:participation")
      resolve(&Participant.confirm_participation_from_token/3)
    end

    @desc "Export the event participants as a file"
    field :export_event_participants, :participant_export do
      arg(:event_id, non_null(:id),
        description: "The ID from the event for which to export participants"
      )

      arg(:roles, list_of(:participant_role_enum),
        default_value: [],
        description: "The participant roles to include"
      )

      arg(:format, :export_format_enum, description: "The format in which to return the file")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Events.Event,
        rule: :"read:event:participants:export",
        args: %{id: :event_id}
      )

      resolve(&Participant.export_event_participants/3)
    end

    @desc "Send private messages to participants"
    field :send_event_private_message, :conversation do
      arg(:event_id, non_null(:id),
        description: "The ID from the event for which to export participants"
      )

      arg(:roles, list_of(:participant_role_enum),
        default_value: [],
        description: "The participant roles to include"
      )

      arg(:text, non_null(:string), description: "The private message body")

      arg(:actor_id, non_null(:id),
        description: "The profile ID to create the private message as"
      )

      arg(:language, :string, description: "The private message language", default_value: "und")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Events.Event,
        rule: :"write:event:participants:private_message",
        args: %{id: :event_id}
      )

      resolve(&Participant.send_private_messages_to_participants/3)
    end

    @desc "Submit a survey response before joining an event"
    field :submit_survey_response, :boolean do
      arg(:context_id, non_null(:string), description: "The survey context ID")
      arg(:survey_id, :string, description: "Specific survey ID (for post-event surveys with multiple surveys per context)")
      arg(:data, non_null(:json), description: "The survey response data")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&Participant.submit_survey_response/3)
    end

    @desc "Confirm joining an event after completing the required survey"
    field :confirm_event_join, :join_event_response do
      arg(:event_id, non_null(:id), description: "The event ID to confirm joining")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&Participant.confirm_event_join/3)
    end
  end

end
