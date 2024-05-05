defmodule Myrmidex.Generators.BinaryTest do
  use Myrmidex.Support.TestCase, async: true
  alias Myrmidex.Generators

  describe "Generators.Binary.string_stream_data/0" do
    property "returns valid stringsiex" do
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
  end
end
