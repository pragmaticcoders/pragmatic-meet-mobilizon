defmodule Mix.Tasks.Mobilizon.Users.ExportCsv do
  @moduledoc """
  Task to export user data to CSV
  """

  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  import Ecto.Query
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  @shortdoc "Export all users data to CSV file"

  @impl Mix.Task
  def run(args) do
    {options, _, _} =
      OptionParser.parse(
        args,
        strict: [output: :string],
        aliases: [o: :output]
      )

    output_file = Keyword.get(options, :output, "users_export.csv")

    start_mobilizon()

    shell_info("Exporting user data to #{output_file}...")

    case export_users_to_csv(output_file) do
      {:ok, count} ->
        shell_info("Successfully exported #{count} users to #{output_file}")

      {:error, reason} ->
        shell_error("Error exporting users: #{inspect(reason)}")
    end
  end

  defp export_users_to_csv(output_file) do
    try do
      # Open the file for writing
      {:ok, file} = File.open(output_file, [:write, :utf8])

      # Write CSV header
      IO.write(file, csv_encode(["User Name", "User Email", "Registration Date", "Groups Joined"]) <> "\n")

      # Query all users with their actors
      users =
        User
        |> where([u], u.disabled == false)
        |> preload([:actors])
        |> Repo.all()

      # Process each user
      count =
        users
        |> Enum.map(fn user -> process_user(user, file) end)
        |> length()

      File.close(file)
      {:ok, count}
    rescue
      e -> {:error, e}
    end
  end

  defp process_user(%User{} = user, file) do
    # Get the user's actors
    actors = Users.get_actors_for_user(user)

    # Get all group memberships for all actors
    groups = get_all_groups_for_user_actors(actors)

    # Get the display name from the default actor or first actor
    user_name = get_user_display_name(actors)

    # Format registration date
    registration_date = format_datetime(user.inserted_at)

    # Format groups as a semicolon-separated list
    groups_str = format_groups(groups)

    # Write CSV row
    row = csv_encode([user_name, user.email, registration_date, groups_str])
    IO.write(file, row <> "\n")
  end

  defp get_all_groups_for_user_actors(actors) do
    actors
    |> Enum.flat_map(fn actor ->
      # Get memberships for this actor
      query =
        from(m in Member,
          join: a in Actor,
          on: m.actor_id == a.id,
          join: p in Actor,
          on: m.parent_id == p.id,
          where: a.id == ^actor.id and m.role not in [:not_approved, :rejected, :invited],
          where: p.type == :Group,
          select: %{
            group_name: p.name,
            group_username: p.preferred_username,
            role: m.role,
            member_since: m.member_since
          }
        )

      Repo.all(query)
    end)
    |> Enum.uniq_by(fn g -> g.group_username end)
  end

  defp get_user_display_name([]), do: "N/A"

  defp get_user_display_name(actors) when is_list(actors) do
    # Get the first actor with a name, or fall back to preferred_username
    actor = List.first(actors)

    cond do
      is_nil(actor) -> "N/A"
      actor.name && actor.name != "" -> actor.name
      true -> "@#{actor.preferred_username}"
    end
  end

  defp format_datetime(nil), do: ""

  defp format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.to_iso8601()
  end

  defp format_datetime(%NaiveDateTime{} = dt) do
    dt
    |> NaiveDateTime.to_iso8601()
  end

  defp format_groups([]), do: ""

  defp format_groups(groups) do
    groups
    |> Enum.map(fn group ->
      name = if group.group_name && group.group_name != "", do: group.group_name, else: "@#{group.group_username}"
      role_part = if group.role != :member, do: " (#{group.role})", else: ""
      "#{name}#{role_part}"
    end)
    |> Enum.join("; ")
  end

  # Simple CSV encoding: escape quotes and wrap in quotes if needed
  defp csv_encode(fields) when is_list(fields) do
    fields
    |> Enum.map(&csv_encode_field/1)
    |> Enum.join(",")
  end

  defp csv_encode_field(field) when is_binary(field) do
    # If field contains comma, newline, or quote, wrap in quotes and escape internal quotes
    if String.contains?(field, [",", "\n", "\r", "\""]) do
      escaped = String.replace(field, "\"", "\"\"")
      "\"#{escaped}\""
    else
      field
    end
  end

  defp csv_encode_field(field), do: to_string(field)
end

