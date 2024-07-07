defmodule Myrmidex.Generators.ApproximateTest do
  use Myrmidex.Case, async: true
  alias Myrmidex.Generators

  describe "Generators.Approximate.approximate_stream_data/3" do
    @date ~D[2020-01-15]
    @time ~T[12:30:00]
    @datetime DateTime.new!(@date, @time)

    defp approximate?(term) when is_integer(term) when is_float(term) do
      term >= 0 and term <= 20
    end

    defp approximate?(%DateTime{minute: minute}) do
      minute >= 29 and minute <= 31
    end

    defp approximate?(%Date{year: _year, month: month, day: day}) do
      month === 1 and day > 1 and day < 30
    end

    defp approximate?(%Time{hour: hour}) do
      hour > 10 and hour < 14
    end

    property "returns matching approximate terms" do
      for term <- [10.0, 10, @date, @time, @datetime] do
        check all term <- Generators.Approximate.approximate_stream_data!(term, []) do
          assert approximate?(term)
        end
      end
    end

    property "limit option restricts upper and lower range limit" do
      check all gte_integer <-
                  Generators.Approximate.approximate_stream_data!(10, limits: [:upper]),
                lte_integer <-
                  Generators.Approximate.approximate_stream_data!(10, limits: [:lower]) do
        assert lte_integer <= 10
        assert gte_integer >= 10
      end
    end

    test "accepts generators" do
      assert 10
             |> SD.constant()
             |> Generators.Approximate.approximate_stream_data!([])
             |> pick()
             |> approximate?()
    end
  end
end
