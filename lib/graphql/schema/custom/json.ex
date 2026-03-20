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

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
