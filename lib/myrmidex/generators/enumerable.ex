defmodule Myrmidex.Generators.Enumerable do
  @moduledoc false
  # List, Map, and other enumerable generators.

  alias StreamData, as: SD

  @doc false
  def enum_stream_data([_ | _] = values) do
    values
    |> SD.member_of()
    |> SD.unshrinkable()
  end

  @doc false
  def fixed_map_stream_data(term, keys) do
    term
    |> maybe_transform_keys(keys)
    |> SD.fixed_map()
  end

  defp maybe_transform_keys(term, type)
       when is_map(term)
       when is_list(term)
       when is_struct(term, Stream) do
    Map.new(term, fn {k, v} ->
      case {type, k} do
        {:string, k} when is_atom(k) ->
          {Atom.to_string(k), v}

        {:atom, k} when is_binary(k) ->
          {String.to_existing_atom(k), v}

        _ ->
          {k, v}
      end
    end)
  end
end
