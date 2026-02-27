defmodule Mobilizon.GraphQL.Schema.InvitationType do
  @moduledoc """
  GraphQL types and operations for group invitation-by-email (token-based).
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Invitation

  @desc "Result of sending a group invitation by email"
  object :group_invitation_sent do
    meta(:authorize, :all)
    field(:success, non_null(:boolean), description: "Whether the invitation was sent")
  end

  @desc "Group invitation details (from token); used when user clicks link in email"
  object :group_invitation do
    meta(:authorize, :all)
    field(:group, :group, description: "The group the user is invited to")
    field(:email, :string, description: "The email the invitation was sent to")
    field(:for_new_user, non_null(:boolean), description: "True if invitee must register first")
  end

  @desc "Result of accepting a group invitation (by token)"
  object :accept_group_invitation_result do
    meta(:authorize, :all)
    field(:member, :member, description: "The new membership when already logged in and accepted")
    field(:requires_registration, non_null(:boolean),
      description: "True when user must register first; use invitation_token in register flow"
    )
    field(:invitation_token, :string,
      description: "Token to pass to registration; present when requires_registration is true"
    )
  end

  @desc "Group invitation queries (token-based links)"
  object :invitation_queries do
    @desc "Get invitation details by token (for accept-invitation page)"
    field :group_invitation_by_token, :group_invitation do
      arg(:token, non_null(:string), description: "The invitation token from the email link")

      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Invitation.group_invitation_by_token/3)
    end
  end
end
