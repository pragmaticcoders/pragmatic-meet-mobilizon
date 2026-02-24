defmodule Mobilizon.Events.EventRegistrationQuestionOption do
  @moduledoc """
  Represents an option for a single_choice or multiple_choice registration question.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.EventRegistrationQuestion

  @type t :: %__MODULE__{
          id: integer(),
          question_id: integer(),
          position: integer(),
          label: String.t()
        }

  schema "event_registration_question_options" do
    field(:position, :integer, default: 0)
    field(:label, :string)

    belongs_to(:question, EventRegistrationQuestion)

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:question_id, :label]
  @optional_attrs [:position]

  @doc false
  def changeset(option, attrs) do
    option
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:label, min: 1, max: 200)
    |> foreign_key_constraint(:question_id)
  end
end
