defmodule Mobilizon.Actors.GroupPostSurvey do
  @moduledoc """
  Represents a survey attached to a group (available to group members).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor

  @statuses ~w(draft published closed)

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          title: String.t(),
          description: String.t() | nil,
          schema: map(),
          status: String.t(),
          context_id: String.t(),
          group_id: integer()
        }

  schema "group_post_surveys" do
    field(:uuid, Ecto.UUID)
    field(:title, :string, default: "")
    field(:description, :string)
    field(:schema, :map, default: %{})
    field(:status, :string, default: "draft")
    field(:context_id, :string)
    belongs_to(:group, Actor)
    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = survey, attrs) do
    survey
    |> cast(attrs, [:title, :description, :schema, :status, :group_id])
    |> validate_required([:group_id])
    |> validate_inclusion(:status, @statuses)
    |> put_uuid_and_context_id()
  end

  @doc false
  def update_changeset(%__MODULE__{} = survey, attrs) do
    survey
    |> cast(attrs, [:title, :description, :schema])
  end

  @doc false
  def status_changeset(%__MODULE__{} = survey, status) when status in @statuses do
    survey
    |> change(status: status)
  end

  defp put_uuid_and_context_id(%Ecto.Changeset{} = changeset) do
    case get_field(changeset, :uuid) do
      nil ->
        uuid = Ecto.UUID.generate()

        changeset
        |> put_change(:uuid, uuid)
        |> put_change(:context_id, "mobilizon_group_survey:#{uuid}")

      _existing ->
        changeset
    end
  end
end
