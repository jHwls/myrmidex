defmodule Myrmidex.Helpers.StreamDataTest do
  use Myrmidex.Support.TestCase, async: true
  doctest Myrmidex.Helpers.StreamData

  alias Myrmidex.Helpers.StreamData, as: SDHelpers
  import ExUnitProperties

  describe "&SDHelpers.monotonic_integer_stream_data/0" do
    test "returns valid, increasing integer ids" do
      stream = SDHelpers.monotonic_integer_stream_data()

      assert stream
             |> Enum.take(10)
             |> Enum.reduce_while(0, fn
               next, prev when next > prev -> {:cont, next}
               _, _ -> {:halt, false}
             end)
    end
  end

  describe "&SDHelpers.uuid_stream_data/0" do
    property "returns valid integer ids" do
      check all id <- SDHelpers.uuid_stream_data() do
        assert is_binary(id)
      end
    end
  end

  describe "&SDHelpers.time_stream_data/0" do
    property "returns valid times" do
      check all time <- SDHelpers.time_stream_data() do
        assert %Time{} = time
      end
    end

    test "accepts hour, min, sec, microsecond options" do
      assert %Time{hour: hour} =
               [hour: 9..12]
               |> SDHelpers.time_stream_data()
               |> Myrmidex.one()

      assert hour >= 9
      assert hour <= 12

      assert %Time{hour: 0, minute: 0, second: 0, microsecond: {0, 6}} =
               [hour: 0, minute: 0, second: 0, microsecond: 0]
               |> SDHelpers.time_stream_data()
               |> Myrmidex.one()
    end
  end

  describe "&SDHelpers.date_stream_data/0" do
    property "returns valid date" do
      check all date <- SDHelpers.date_stream_data() do
        assert %Date{} = date
      end
    end
  end

  describe "&SDHelpers.datetime_stream_data/0" do
    property "returns valid utc_datetime_usec data" do
      check all datetime <- SDHelpers.datetime_stream_data() do
        assert %DateTime{
                 utc_offset: 0
               } = datetime
      end
    end

    property "can return utc_datetime data" do
      check all datetime <- SDHelpers.datetime_stream_data(:utc_datetime) do
        assert %DateTime{microsecond: {0, 0}} = datetime
      end
    end
  end

  describe "&SDHelpers.string_stream_data/0" do
    property "returns valid string" do
      check all string <- SD.string(:alphanumeric),
                string <- SDHelpers.string_stream_data(string) do
        assert is_binary(string)
      end
    end
  end
end
