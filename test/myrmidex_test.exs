defmodule MyrmidexTest do
  use Myrmidex.Support.TestCase, async: true
  doctest Myrmidex, except: [:moduledoc]

  alias Myrmidex.Support.Fixtures.{EctoSchema, TestPumpkin}

  describe "&Myrmidex.to_stream/1 with an Ecto schema" do
    @opts []
    test "provides sensible defaults via reflection" do
      assert %StreamData{} = stream_data = Myrmidex.to_stream(%EctoSchema{}, @opts)

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
      assert %StreamData{} = Myrmidex.to_stream(EctoSchema, @opts)
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

    @opts [keys: :string]
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
  end

  describe "&Myrmidex.one/2 & &Myrmidex.many/3" do
    property "return one from any stream" do
      check all term <- SD.term() do
        generated_term = Myrmidex.one(SD.repeatedly(fn -> term end))
        assert match?(^term, generated_term)
      end
    end

    property "return many from a stream" do
      check all term <- SD.term() do
        assert [generated_term | _] = Myrmidex.many(SD.repeatedly(fn -> term end))
        assert match?(^term, generated_term)
      end
    end

    test "returns one or many Ecto schemas" do
      assert %EctoSchema{} = Myrmidex.one(%EctoSchema{}, @opts)
      assert [%EctoSchema{} | _] = Myrmidex.many(%EctoSchema{}, 10, @opts)
    end

    test "returns one or many structs" do
      assert %TestPumpkin{} = Myrmidex.one(%TestPumpkin{}, @opts)
      assert [%TestPumpkin{} | _] = Myrmidex.many(%TestPumpkin{}, 10, @opts)
    end
  end

  describe "&Myrmidex.affix/2" do
    @values %{value: 2, other_value: nil}

    test "maps given overrides into constant streams" do
      assert %{value: %SD{}, other_value: nil} = Myrmidex.affix(@values, %{value: 4})
      assert %{value: %SD{}, other_value: nil} = Myrmidex.affix(@values, value: nil)
    end

    test "" do
      assert %{value: %SD{}, other_value: nil} = Myrmidex.affix(@values, %{value: 4})
      assert %{value: %SD{}, other_value: nil} = Myrmidex.affix(@values, value: nil)
    end
  end

  describe "&Myrmidex.affix_many/2 and &Myrmidex.affix_many/3" do
    @values %{value: 2, other_value: nil}

    test "maps given overrides into list_of streams" do
      assert %{value: %SD{}, other_value: nil} = Myrmidex.affix_many(@values, %{value: 4})
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
end
