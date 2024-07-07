defmodule Myrmidex.GeneratorSchemas.DefaultTest do
  use Myrmidex.Case, async: true
  alias Myrmidex.GeneratorSchemas.Default, as: DefaultSchema

  describe "c:DefaultSchema.cast/3 (via GeneratorSchema.__cast__/3)" do
    property "casts any term to a matching generator" do
      check all term <- SD.term(), max_runs: 100 do
        assert %SD{} = stream = DefaultSchema.cast(term, [])
        assert matching_generator?(pick(stream), term)
      end
    end

    test "casts nil to a nil generator" do
      assert %SD{} = stream = DefaultSchema.cast(nil, [])
      assert matching_generator?(pick(stream), nil)
    end

    test "casts datetime structs to matching generators" do
      for term <- [Date.utc_today(), Time.utc_now(), DateTime.utc_now()] do
        assert %SD{} = stream = DefaultSchema.cast(term, [])
        assert matching_generator?(pick(stream), term)
      end
    end
  end
end
