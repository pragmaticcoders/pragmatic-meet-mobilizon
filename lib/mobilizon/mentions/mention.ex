defmodule Mobilizon.Mention do
  @moduledoc """
  The Mentions context.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo
  
  require Logger

  @type t :: %__MODULE__{
          silent: boolean,
          actor: Actor.t(),
          event: Event.t(),
          comment: Comment.t()
        }

  @required_attrs [:actor_id]
  @optional_attrs [:silent, :event_id, :comment_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "mentions" do
    field(:silent, :boolean, default: false)
    belongs_to(:actor, Actor)
    belongs_to(:event, Event)
    belongs_to(:comment, Comment)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(mention, attrs) do
    Logger.debug("[Mention changeset] Creating mention changeset")
    Logger.debug("[Mention changeset] Mention: #{inspect(mention)}")
    Logger.debug("[Mention changeset] Attrs: #{inspect(attrs)}")
    Logger.debug("[Mention changeset] Actor ID: #{Map.get(attrs, :actor_id)}")
    Logger.debug("[Mention changeset] Actor ID (string key): #{Map.get(attrs, "actor_id")}")
    Logger.debug("[Mention changeset] Event ID: #{Map.get(attrs, :event_id)}")
    Logger.debug("[Mention changeset] Comment ID: #{Map.get(attrs, :comment_id)}")
    Logger.debug("[Mention changeset] Silent: #{Map.get(attrs, :silent)}")
    
    result = mention
    |> cast(attrs, @attrs)
    # TODO: Enforce having either event_id or comment_id
    |> validate_required(@required_attrs)
    
    Logger.debug("[Mention changeset] Final changeset: #{inspect(result)}")
    Logger.debug("[Mention changeset] Changeset valid?: #{result.valid?}")
    if not result.valid? do
      Logger.debug("[Mention changeset] Changeset errors: #{inspect(result.errors)}")
    end
    
    result
  end

  @doc """
  Creates a new mention
  """
  @spec create_mention(map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def create_mention(args) do
    Logger.debug("[Mention create_mention] Creating new mention")
    Logger.debug("[Mention create_mention] Args: #{inspect(args)}")
    
    changeset = %__MODULE__{} |> changeset(args)
    Logger.debug("[Mention create_mention] Changeset created: #{inspect(changeset)}")
    
    case Repo.insert(changeset) do
      {:ok, %__MODULE__{} = mention} ->
        Logger.debug("[Mention create_mention] Mention inserted successfully: #{inspect(mention)}")
        
        preloaded_mention = Repo.preload(mention, [:actor, :event, :comment])
        Logger.debug("[Mention create_mention] Preloaded mention: #{inspect(preloaded_mention)}")
        Logger.debug("[Mention create_mention] Preloaded actor: #{inspect(preloaded_mention.actor)}")
        Logger.debug("[Mention create_mention] Preloaded event: #{inspect(preloaded_mention.event)}")
        Logger.debug("[Mention create_mention] Preloaded comment: #{inspect(preloaded_mention.comment)}")
        
        {:ok, preloaded_mention}
        
      {:error, changeset} ->
        Logger.debug("[Mention create_mention] Failed to insert mention: #{inspect(changeset)}")
        Logger.debug("[Mention create_mention] Insert errors: #{inspect(changeset.errors)}")
        {:error, changeset}
        
      other ->
        Logger.debug("[Mention create_mention] Unexpected result: #{inspect(other)}")
        other
    end
  end
end
