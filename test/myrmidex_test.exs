defmodule MyrmidexTest do
  use Myrmidex.Case, async: true
  doctest Myrmidex, except: [:moduledoc]

  alias Myrmidex.Support.Fixtures.{EctoSchema, TestPumpkin}

  describe "Myrmidex.to_stream/2 with an Ecto schema" do
    @opts []
    test "provides sensible defaults via reflection" do
      assert %SD{} = stream_data = Myrmidex.to_stream(%EctoSchema{}, @opts)

      assert %{
               id: id,
               contract: nil,
               inserted_at: %DateTime{},
               open_int: open_int,
               prev_close: prev_close,
               price: price,
               symbol_id: nil,
               symbol: nil,
               trades: nil,
               volume: volume
             } = pick(stream_data)

      assert is_integer(id)
      assert is_integer(open_int)
      assert is_integer(volume)
      assert is_float(price)
      assert is_float(prev_close)
    end

    @opts []
    test "accepts a schema module" do
      assert %SD{} = Myrmidex.to_stream(EctoSchema, @opts)
    end

    @opts []
    test "can be passed through further Stream functions" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(%EctoSchema{}, @opts)

      assert [%{price: 42}] =
               stream_data
               |> Stream.map(&Map.put(&1, :price, 42))
               |> Enum.take(1)
    end

    @opts []
    test "respects field-level overrides" do
      assert %StreamData{} =
               stream_data =
               Myrmidex.to_stream(%EctoSchema{open_int: StreamData.constant(42)}, @opts)

      assert %{open_int: 42} = pick(stream_data)
    end

    @opts [attr_keys: :string]
    test "maps to string keys via opts" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(%EctoSchema{}, @opts)

      assert %{
               "id" => _,
               "contract" => _,
               "inserted_at" => _,
               "open_int" => _,
               "prev_close" => _,
               "price" => _,
               "symbol" => _,
               "symbol_id" => _,
               "trades" => _,
               "volume" => _
             } = pick(stream_data)
    end

    @opts [drop_autogenerate?: true]
    test "excludes autogenerate fields via opt" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(%EctoSchema{}, @opts)
      assert %{} = attrs = pick(stream_data)
      refute Map.has_key?(attrs, :id)
      refute Map.has_key?(attrs, :timestamp)
    end

    @opts [drop_associations?: true]
    test "excludes associations fields via opt" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(%EctoSchema{}, @opts)
      assert %{} = attrs = pick(stream_data)
      refute Map.has_key?(attrs, :contract)
    end

    @opts [drop_associations?: true, drop_autogenerate?: true]
    test "field-level overrides overrule opts" do
      assert %StreamData{} =
               stream_data =
               %EctoSchema{}
               |> Myrmidex.affix(%{id: 1, symbol_id: "D"})
               |> Myrmidex.to_stream(@opts)

      assert %{id: 1, symbol_id: "D"} = pick(stream_data)
    end
  end

  describe "Myrmidex.to_stream/2 with a map" do
    @term %{string: "String", number: 1.23, map: %{one: 1, two: 2}, empty_map: %{}}
    @opts []
    test "provides sensible defaults via matching" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(@term, @opts)

      assert %{
               string: string,
               number: number,
               map: %{one: _, two: _},
               empty_map: %{}
             } = pick(stream_data)

      assert is_binary(string)
      assert is_float(number)
    end

    @opts [attr_keys: :string]
    test "maps to string keys via opts" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(@term, @opts)

      assert %{
               "string" => string,
               "number" => number
             } = pick(stream_data)

      assert is_binary(string)
      assert is_float(number)
    end

    @term %{"key" => "value"}
    @opts []
    test "matches key type of the term by default" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(@term, @opts)
      assert %{"key" => _} = pick(stream_data)
    end
  end

  describe "Myrmidex.to_stream/2 with any term" do
    @opts []
    test "returns stream_data" do
      stream_data = StreamData.constant(1)
      assert %StreamData{} = stream_data = Myrmidex.to_stream(stream_data, @opts)
      assert 1 = pick(stream_data)
    end
  end

  describe "Myrmidex.one/2 & Myrmidex.many/3" do
    @opts []

    property "return one from any term" do
      check all term <- SD.term() do
        generated_term = Myrmidex.one(SD.repeatedly(fn -> term end))
        assert match?(^term, generated_term)
      end
    end

    property "return many from any term" do
      check all term <- SD.term() do
        assert [generated_term | _] = Myrmidex.many(SD.repeatedly(fn -> term end))
        assert match?(^term, generated_term)
      end
    end

    test "returns a representative from a vanilla stream" do
      stream = Stream.map([1, 2, 3], & &1)
      1 = Myrmidex.one(stream, @opts)
      [1, 2] = Myrmidex.many(stream, 2, @opts)
    end

    test "returns one or many Ecto schemas" do
      assert %EctoSchema{} = Myrmidex.one(%EctoSchema{}, @opts)
      assert [%EctoSchema{} | _] = Myrmidex.many(%EctoSchema{}, 2, @opts)
    end

    test "returns one or many structs" do
      assert %TestPumpkin{} = Myrmidex.one(%TestPumpkin{}, @opts)
      assert [%TestPumpkin{} | _] = Myrmidex.many(%TestPumpkin{}, 2, @opts)
    end
  end

  describe "Myrmidex.affix/2" do
    @term %{value: 2, other_value: nil}
    test "maps given overrides into constant streams" do
      assert %{value: %SD{} = generator, other_value: nil} = Myrmidex.affix(@term, %{value: 4})
      assert constant_generator?(generator, 4)
      assert %{value: %SD{} = generator, other_value: nil} = Myrmidex.affix(@term, value: nil)
      assert constant_generator?(generator, nil)
    end

    test "respects atom-keyed maps when applying overrides" do
      assert %{value: %SD{}, other_value: nil} =
               Myrmidex.affix(@term, %{value: 4})

      assert %{value: %SD{}, other_value: nil} =
               Myrmidex.affix(@term, %{"value" => 4})
    end

    @term %{"value" => 2, "other_value" => nil}
    test "respects string-keyed maps when applying overrides" do
      assert %{"value" => %SD{}, "other_value" => nil} =
               Myrmidex.affix(@term, value: 4)

      assert %{"value" => %SD{}, "other_value" => nil} =
               Myrmidex.affix(@term, %{"value" => 4})
    end

    @term %{"value" => 2, other_value: nil}
    test "is agnostic to mixed-keyed maps when applying overrides" do
      assert %{value: %SD{}, other_value: nil} =
               Myrmidex.affix(@term, value: 4)

      assert %{"value" => %SD{}, other_value: nil} =
               Myrmidex.affix(@term, %{"value" => 4})
    end
  end

  describe "Myrmidex.affix/2 & Myrmidex.to_stream/2" do
    @term %{string: "String", number: 1.23, map: %{one: 1, two: 2}, empty_map: %{}}
    @opts [attr_keys: :string]
    test "affixes any given overrides" do
      assert %SD{} =
               stream_data =
               @term
               |> Myrmidex.affix(number: 4)
               |> Myrmidex.to_stream(@opts)

      assert %{"number" => 4} = pick(stream_data)

      assert %SD{} =
               stream_data =
               @term
               |> Myrmidex.affix(%{"number" => 4})
               |> Myrmidex.to_stream(@opts)

      assert %{"number" => 4} = pick(stream_data)
    end
  end

  describe "Myrmidex.affix_many/2 and Myrmidex.affix_many/3" do
    @term %{value: 2, other_value: nil}

    test "maps given overrides into list_of streams" do
      assert %{value: %SD{}, other_value: nil} = Myrmidex.affix_many(@term, %{value: 4})
    end

    property "nests a list of term into an object" do
      check all term <- SD.term() do
        assert %{trades: [^term | _]} =
                 %EctoSchema{}
                 |> Myrmidex.affix_many(trades: term)
                 |> Myrmidex.one()
      end
    end

    test "accepts a stream" do
      assoc_stream = Myrmidex.to_stream(%EctoSchema.Child{})

      assert %{trades: [%{id: _, snapshot: _, snapshot_id: _, symbol: _} | _]} =
               %EctoSchema{}
               |> Myrmidex.affix_many(%{trades: assoc_stream})
               |> Myrmidex.one()
    end

    test "allows specifying a range size" do
      assert %{trades: [4 | _] = trades} =
               %EctoSchema{}
               |> Myrmidex.affix_many(1..4, %{trades: SD.constant(4)})
               |> Myrmidex.one()

      assert length(trades) < 5
    end
  end

  describe "Myrmidex.via!/2" do
    test "repeatedly applies a 1-arity function to the result of a stream" do
      assert %SD{} =
               stream_data =
               1
               |> Myrmidex.to_stream(limit_generation?: true)
               |> Myrmidex.via!(&(&1 * 2))

      assert Enum.all?(Myrmidex.many(stream_data), &(&1 === 2))
    end

    test "raises when the 1st argument is not a stream" do
      assert_raise ArgumentError, "first argument must be stream data; received `1`", fn ->
        Myrmidex.via!(1, &(&1 * 2))
      end
    end
  end
end
