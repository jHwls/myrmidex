defmodule Myrmidex.GeneratorSchemaTest do
  use Myrmidex.Case, async: true
  alias Myrmidex.GeneratorSchema
  alias Myrmidex.GeneratorSchemas.Default, as: DefaultSchema
  import ExUnitProperties

  alias Myrmidex.Support.Fixtures.{EctoSchema, EmbeddedSchema, JSON, TestPumpkin}

  describe "GeneratorSchema.implementer?/1" do
    test "returns true for GeneratorSchema behaviour implementers" do
      assert GeneratorSchema.implementer?(DefaultSchema)
      refute GeneratorSchema.implementer?(EctoSchema)
    end
  end

  describe "GeneratorSchema.__cast__/3 with structs" do
    test "casts Ecto schemas into fixed_map generators" do
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, %EctoSchema{})
      assert %{id: int} = pick(stream)
      assert is_integer(int)
    end

    test "casts Ecto embedded schemas into fixed_map generators" do
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, %EmbeddedSchema{})

      assert %{
               date: %Date{},
               time: %Time{},
               preferred_time: %DateTime{},
               valid?: valid?,
               preference: :"🎃"
             } = pick(stream)

      assert is_boolean(valid?)
    end

    test "casts structs into fixed_map generators" do
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, %TestPumpkin{})

      assert %{
               name: name,
               favorite_date: %{},
               age_in_months: age,
               eats: food,
               material: material
             } = pick(stream)

      assert is_binary(name)
      assert is_integer(age)
      assert is_binary(food)
      assert is_atom(material)
    end

    test "does not override affixed streams" do
      affixed = Myrmidex.affix(%EctoSchema{}, id: "A")
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, affixed)
      assert %{id: "A"} = pick(stream)

      affixed = Myrmidex.affix_many(%EctoSchema{}, id: "A")
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, affixed)
      assert %{id: ["A" | _]} = pick(stream)
    end
  end

  describe "GeneratorSchema.__cast__/3 with maps" do
    @json JSON.balance_transaction()

    test "casts maps into fixed_map generators" do
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, @json)

      assert %{
               "id" => _,
               "amount" => _,
               "created" => _,
               "available_on" => _,
               "currency" => _,
               "object" => _
             } = pick(stream)
    end

    test "optionally outputs atom or string keys" do
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, @json, attr_keys: :atom)

      assert %{
               id: _,
               amount: _,
               created: _,
               available_on: _,
               currency: _,
               object: _
             } = pick(stream)
    end

    test "optionally limits generation" do
      assert %SD{} =
               stream =
               GeneratorSchema.__cast__(DefaultSchema, @json, limit_generation?: true)

      assert @json = pick(stream)
    end
  end

  describe "GeneratorSchema.__cast_field__/3" do
    test "raises usefully when no matching impl" do
      assert_raise Myrmidex.MissingGeneratorError,
                   "Myrmidex.GeneratorSchemas.Default does not define an implementation for Myrmidex.GeneratorSchemas.Default.cast_field/2 for arguments: [{:id, :binary_id, nil}, []]",
                   fn ->
                     GeneratorSchema.__cast_field__(DefaultSchema, {:id, :binary_id, nil}, [])
                   end
    end
  end

  describe "GeneratorSchema.to_field_generator_tuple_stream/3" do
    defp build_and_enumerate_stream(term) do
      term
      |> GeneratorSchema.to_field_generator_tuple_stream(DefaultSchema, [])
      |> Enum.map(& &1)
    end

    defp all_fields?(field_generators, term) do
      term
      |> Map.from_struct()
      |> Map.delete(:__meta__)
      |> map_size()
      |> Kernel.===(length(field_generators))
    end

    defp all_generators?(field_generators) do
      field_generators
      |> Keyword.values()
      |> Enum.all?(&stream_data?/1)
    end

    test "maps every field in an ecto schema to a generator" do
      field_generators = build_and_enumerate_stream(%EctoSchema{})
      assert all_fields?(field_generators, %EctoSchema{})
      assert all_generators?(field_generators)
    end

    test "maps every field in a struct to a generator" do
      field_generators = build_and_enumerate_stream(%TestPumpkin{})
      assert all_fields?(field_generators, %TestPumpkin{})
      assert all_generators?(field_generators)
    end
  end
end
