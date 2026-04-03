defmodule Mobilizon.GraphQL.Schema.Custom.JSON do
  @moduledoc """
  The JSON scalar type allows arbitrary JSON objects to be passed in and out.
  """
  use Absinthe.Schema.Notation

  scalar :json, name: "JSON" do
    description("Arbitrary JSON value")
    serialize(&encode/1)
    parse(&decode/1)
  end

  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> {:ok, value}
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Integer{value: value}), do: {:ok, value}
  defp decode(%Absinthe.Blueprint.Input.Float{value: value}), do: {:ok, value}
  defp decode(%Absinthe.Blueprint.Input.Boolean{value: value}), do: {:ok, value}
  defp decode(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}

  defp decode(%Absinthe.Blueprint.Input.Object{fields: fields}) do
    map =
      fields
      |> Enum.map(fn %{name: name, input_value: %{normalized: normalized}} ->
        case decode(normalized) do
          {:ok, val} -> {name, val}
          :error -> {name, nil}
        end
      end)
      |> Map.new()

    {:ok, map}
  end

  defp decode(%Absinthe.Blueprint.Input.List{items: items}) do
    list =
      Enum.map(items, fn %{normalized: normalized} ->
        case decode(normalized) do
          {:ok, val} -> val
          :error -> nil
        end
      end)

    {:ok, list}
  end

  # When the argument is passed as a GraphQL variable (not inline literal),
  # Absinthe coerces it to plain Elixir values before calling parse/1.
  # We must accept maps, lists, and primitives here too.
  defp decode(value) when is_map(value), do: {:ok, value}
  defp decode(value) when is_list(value), do: {:ok, value}
  defp decode(value) when is_binary(value), do: {:ok, value}
  defp decode(value) when is_number(value), do: {:ok, value}
  defp decode(value) when is_boolean(value), do: {:ok, value}
  defp decode(nil), do: {:ok, nil}

  defp decode(_) do
    :error
  end
  defp encode(value), do: value
end
