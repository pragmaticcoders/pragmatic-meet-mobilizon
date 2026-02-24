defmodule Mobilizon.Events.EventRegistrationQuestion do
  @moduledoc """
  Represents a custom question in an event's registration form.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.{Event, EventRegistrationQuestionOption}

  @question_types ~w(short_text long_text single_choice multiple_choice)a

  @type t :: %__MODULE__{
          id: integer(),
          event_id: integer(),
          position: integer(),
          question_type: atom(),
          title: String.t(),
          required: boolean(),
          options: [EventRegistrationQuestionOption.t()]
        }

  schema "event_registration_questions" do
    field(:position, :integer, default: 0)
    field(:question_type, Ecto.Enum, values: @question_types)
    field(:title, :string)
    field(:required, :boolean, default: false)

    belongs_to(:event, Event)
    has_many(:options, EventRegistrationQuestionOption, foreign_key: :question_id)
    has_many(:answers, Mobilizon.Events.ParticipantRegistrationAnswer, foreign_key: :question_id)

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:event_id, :question_type, :title]
  @optional_attrs [:position, :required]

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_inclusion(:question_type, @question_types)
    |> validate_length(:title, min: 1, max: 500)
    |> foreign_key_constraint(:event_id)
    |> cast_assoc(:options, with: &EventRegistrationQuestionOption.changeset/2)
  end
end
