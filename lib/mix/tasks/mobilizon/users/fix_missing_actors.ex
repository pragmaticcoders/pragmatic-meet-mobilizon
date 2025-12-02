defmodule Mix.Tasks.Mobilizon.Users.FixMissingActors do
  @moduledoc """
  Task to fix users who don't have default actors.
  
  This task finds all confirmed users (email/password registration) who don't have
  a default actor and creates one for them.
  
  ## Usage
  
      mix mobilizon.users.fix_missing_actors [--dry-run]
  
  ## Options
  
    * `--dry-run` - Only show what would be done without making changes
  
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User
  require Logger

  @shortdoc "Fix users without default actors"

  @impl Mix.Task
  def run(args) do
    {options, [], []} =
      OptionParser.parse(
        args,
        strict: [
          dry_run: :boolean
        ]
      )

    dry_run = Keyword.get(options, :dry_run, false)

    # Only start app if not already running (e.g. when called via mix, not via bin/mobilizon eval)
    unless Application.started_applications() |> Enum.any?(fn {app, _, _} -> app == :mobilizon end) do
      start_mobilizon()
    end

    if dry_run do
      shell_info("🔍 Running in DRY-RUN mode - no changes will be made\n")
    end

    # Find all users without default actors (email/password users only)
    users_without_actors = find_users_without_actors()

    shell_info("Found #{length(users_without_actors)} user(s) without default actors\n")

    if length(users_without_actors) == 0 do
      shell_info("✅ All users have actors - nothing to fix!")
      :ok
    else
      results =
        users_without_actors
        |> Enum.map(fn user ->
          fix_user_actor(user, dry_run)
        end)

      # Count successes and failures
      successes = Enum.count(results, fn {status, _} -> status == :ok end)
      failures = Enum.count(results, fn {status, _} -> status == :error end)

      shell_info("\n" <> String.duplicate("=", 60))

      if dry_run do
        shell_info("DRY-RUN Summary:")
        shell_info("  - Would create actors for: #{successes} user(s)")
        shell_info("  - Would fail for: #{failures} user(s)")
        shell_info("\nRun without --dry-run to apply changes")
      else
        shell_info("Summary:")
        shell_info("  - Successfully created actors: #{successes}")
        shell_info("  - Failed: #{failures}")

        if successes > 0 do
          shell_info("\n✅ Fixed #{successes} user(s)!")
        end

        if failures > 0 do
          shell_error("\n❌ Failed to fix #{failures} user(s) - check logs for details")
        end
      end
    end
  end

  @spec find_users_without_actors() :: [User.t()]
  defp find_users_without_actors do
    import Ecto.Query

    # Find all confirmed email/password users without default actors
    Mobilizon.Users.User
    |> where([u], is_nil(u.default_actor_id))
    |> where([u], is_nil(u.provider))
    |> where([u], not is_nil(u.confirmed_at))
    |> where([u], u.disabled == false)
    |> Mobilizon.Storage.Repo.all()
  end

  @spec fix_user_actor(User.t(), boolean()) :: {:ok, Actor.t()} | {:error, any()}
  defp fix_user_actor(%User{email: email, id: user_id} = user, dry_run) do
    # Check if user already has actors (but default_actor_id is not set)
    existing_actors = Users.get_actors_for_user(user)

    cond do
      # User has existing actors - just set the first one as default
      length(existing_actors) > 0 ->
        first_actor = hd(existing_actors)

        if dry_run do
          shell_info(
            "Would set existing actor '#{first_actor.preferred_username}' as default for: #{email}"
          )

          {:ok, first_actor}
        else
          shell_info(
            "Setting existing actor '#{first_actor.preferred_username}' as default for: #{email}"
          )

          _updated_user = Users.update_user_default_actor(user, first_actor)
          {:ok, first_actor}
        end

      # User has no actors - create one
      true ->
        username = generate_unique_username_from_email(email)

        if dry_run do
          shell_info("Would create actor '#{username}' for: #{email}")
          {:ok, %Actor{preferred_username: username}}
        else
          shell_info("Creating actor '#{username}' for: #{email}")

          case Actors.new_person(
                 %{
                   user_id: user_id,
                   preferred_username: username,
                   name: username,
                   summary: ""
                 },
                 true
               ) do
            {:ok, actor} ->
              shell_info("  ✅ Created actor '#{actor.preferred_username}' for: #{email}")
              {:ok, actor}

            {:error, error} ->
              shell_error("  ❌ Failed to create actor for #{email}: #{inspect(error)}")
              {:error, error}
          end
        end
    end
  end

  @spec generate_unique_username_from_email(String.t()) :: String.t()
  defp generate_unique_username_from_email(email) do
    base_username = generate_username_from_email(email)

    # Try the base username first
    case Actors.get_local_actor_by_name(base_username) do
      nil -> base_username
      _actor -> generate_unique_username_with_suffix(base_username, 1)
    end
  end

  @spec generate_unique_username_with_suffix(String.t(), integer()) :: String.t()
  defp generate_unique_username_with_suffix(base_username, attempt) when attempt <= 100 do
    # Generate a random 4-digit suffix
    suffix = :rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")
    candidate = "#{base_username}_#{suffix}"

    case Actors.get_local_actor_by_name(candidate) do
      nil -> candidate
      _actor -> generate_unique_username_with_suffix(base_username, attempt + 1)
    end
  end

  defp generate_unique_username_with_suffix(_base_username, _attempt) do
    # Fallback after 100 attempts - use timestamp
    "user_#{System.system_time(:second)}"
  end

  @spec generate_username_from_email(String.t()) :: String.t()
  defp generate_username_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "")
    # Leave room for suffix
    |> String.slice(0, 16)
    |> case do
      "" -> "user"
      username -> username
    end
  end
end
