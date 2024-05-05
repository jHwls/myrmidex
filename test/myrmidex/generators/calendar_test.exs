defmodule Myrmidex.Generators.CalendarTest do
  use Myrmidex.Support.TestCase, async: true
  alias Myrmidex.Generators

  describe "Generators.Calendar.time_stream_data/0" do
    property "returns valid times" do
      check all time <- Generators.Calendar.time_stream_data([]) do
        assert %Time{} = time
      end
    end

    test "accepts hour, min, second, microsecond options" do
      assert %Time{hour: hour} =
               [hour: 9..12]
               |> Generators.Calendar.time_stream_data()
               |> Myrmidex.one()

      assert hour >= 9
      assert hour <= 12

      assert %Time{hour: 0, minute: 0, second: 0, microsecond: {0, 6}} =
               [hour: 0, minute: 0, second: 0, microsecond: 0]
               |> Generators.Calendar.time_stream_data()
               |> Myrmidex.one()
    end
  end

  describe "Generators.Calendar.date_stream_data/0" do
    property "returns valid dates" do
      check all date <- Generators.Calendar.date_stream_data([]) do
        assert %Date{} = date
      end
    end
  end

  describe "Generators.Calendar.datetime_stream_data/0" do
    property "returns valid utc_datetime_usec data" do
      check all datetime <- Generators.Calendar.datetime_stream_data([]) do
        assert %DateTime{
                 utc_offset: 0
               } = datetime
      end
    end

    property "can return utc_datetime data" do
      check all datetime <- Generators.Calendar.datetime_stream_data(precision: :second) do
        assert %DateTime{microsecond: {0, 0}} = datetime
      end
    end
  end
end
