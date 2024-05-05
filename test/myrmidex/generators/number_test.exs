defmodule Myrmidex.Generators.NumberTest do
  use Myrmidex.Support.TestCase, async: true
  alias Myrmidex.Generators

  describe "Generators.Number.integer_stream_data/0 & Generators.Number.integer_stream_data/1" do
    property "generates integers" do
      check all int <- Generators.Number.integer_stream_data(),
                constant_int <- Generators.Number.integer_stream_data(1),
                range_int <- Generators.Number.integer_stream_data(1..19) do
        assert is_integer(int)
        assert constant_int === 1
        assert range_int < 20 and range_int > 0
      end
    end
  end

  describe "Generators.Number.monotonic_integer_stream_data/0" do
    test "returns valid, increasing integer ids" do
      stream = Generators.Number.monotonic_integer_stream_data()

      assert stream
             |> Enum.take(10)
             |> Enum.reduce_while(0, fn
               next, prev when next > prev -> {:cont, next}
               _, _ -> {:halt, false}
             end)
    end
  end
end
