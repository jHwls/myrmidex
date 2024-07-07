defmodule Myrmidex.Generators.Number do
  @moduledoc false
  # Integer, Float, and related generators.

  alias StreamData, as: SD

  @doc false
  @spec integer_stream_data :: SD.t(number())
  @spec integer_stream_data(term) :: SD.t(number())
  def integer_stream_data, do: SD.integer()
  def integer_stream_data(int) when is_integer(int), do: SD.constant(int)
  def integer_stream_data(%Range{} = range), do: SD.integer(range)

  @doc false
  def monotonic_integer_stream_data do
    SD.repeatedly(fn -> System.unique_integer([:positive, :monotonic]) end)
  end

  @doc false
  def counter_stream_data(start, step) do
    counter_ref = :counters.new(1, [])
    :counters.add(counter_ref, 1, start)

    step
    |> integer_stream_data()
    |> SD.bind(fn increase ->
      SD.repeatedly(fn ->
        :counters.add(counter_ref, 1, increase)
        :counters.get(counter_ref, 1)
      end)
    end)
  end
end
