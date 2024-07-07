defmodule Myrmidex.Generators.BinaryTest do
  use Myrmidex.Case, async: true
  alias Myrmidex.Generators

  describe "Generators.Binary.string_stream_data/0" do
    property "returns valid strings" do
      check all string <- SD.string(:alphanumeric),
                string <- Generators.Binary.string_stream_data(string) do
        assert is_binary(string)
        assert String.valid?(string)
      end
    end
  end

  describe "Generators.Binary.uuid_stream_data/0" do
    property "returns valid binary ids" do
      check all id <- Generators.Binary.uuid_stream_data() do
        assert is_binary(id)
      end
    end

    test "accepts prefix opt" do
      stream_data = Generators.Binary.uuid_stream_data(prefix: "ant_")
      assert ["ant", _] = String.split(pick(stream_data), "_")
    end

    test "accepts suffix opts" do
      stream_data = Generators.Binary.uuid_stream_data(suffix: "_ant")
      assert [_, "ant"] = String.split(pick(stream_data), "_")
    end

    test "ignores irrelevant opts" do
      stream_data = Generators.Binary.uuid_stream_data(elsefix: "_ant")
      refute String.contains?(pick(stream_data), "_ant")
    end
  end
end
