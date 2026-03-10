defmodule Mobilizon.GraphQL.Resolvers.Invitation do
  @moduledoc """
  Resolvers for group invitation-by-email (token-based) query.
  """
  alias Mobilizon.Invitations
  import Mobilizon.Web.Gettext

  @doc """
  Returns invitation details by token. Used when user opens the link from email.
  """
  @spec group_invitation_by_token(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map() | nil} | {:error, String.t()}
  def group_invitation_by_token(_parent, %{token: token}, _resolution) do
    case Invitations.get_invitation_by_token(token) do
      {:ok, inv} ->
        {:ok,
         %{
           group: inv.group,
           email: inv.email,
           for_new_user: inv.for_new_user
         }}

      {:error, :not_found} ->
        {:ok, nil}

      {:error, :expired} ->
        {:error, dgettext("errors", "Invitation has expired")}

      {:error, :already_used} ->
        {:error, dgettext("errors", "Invitation has already been used")}

      {:error, :group_not_found} ->
        {:error, dgettext("errors", "The group you were invited to no longer exists")}
    end
  end
end
