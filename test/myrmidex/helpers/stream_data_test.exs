defmodule Myrmidex.Helpers.StreamDataTest do
  use Myrmidex.Case
  alias Myrmidex.Helpers

  describe "stream_data?/1" do
    test "returns true for stream_data structs" do
      assert Helpers.StreamData.stream_data?(SD.constant(1))
    end

    property "returns false for all other terms" do
      check all term <- SD.term() do
        refute Helpers.StreamData.stream_data?(term)
      end
    end
  end
end
