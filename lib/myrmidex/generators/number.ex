defmodule Myrmidex.Generators.Number do
  @moduledoc false
  # Integer, Float, and related generators.

  alias StreamData, as: SD

  @doc false
  def integer_stream_data, do: SD.integer()
  def integer_stream_data(int) when is_integer(int), do: SD.constant(int)
  def integer_stream_data(%Range{} = range), do: SD.integer(range)

  @doc false
  def monotonic_integer_stream_data do
    SD.repeatedly(fn -> System.unique_integer([:positive, :monotonic]) end)
  end

end
