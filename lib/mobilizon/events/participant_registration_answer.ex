defmodule Mobilizon.Events.ParticipantRegistrationAnswer do
  @moduledoc """
  Represents a participant's answer to an event registration question.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.{EventRegistrationQuestion, Participant}

  @type t :: %__MODULE__{
          id: integer(),
          participant_id: Ecto.UUID.t(),
          question_id: integer(),
          value: String.t()
        }

  schema "participant_registration_answers" do
    field(:value, :string)

    belongs_to(:participant, Participant, type: :binary_id)
    belongs_to(:question, EventRegistrationQuestion)

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:participant_id, :question_id, :value]
  @optional_attrs []

  @doc false
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:value, max: 10_000)
    |> unique_constraint([:participant_id, :question_id])
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:question_id)
  end
end
