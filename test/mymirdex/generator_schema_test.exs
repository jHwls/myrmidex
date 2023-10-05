defmodule Myrmidex.GeneratorSchemaTest do
  use Myrmidex.Support.TestCase, async: true
  alias Myrmidex.GeneratorSchema
  alias Myrmidex.GeneratorSchemas.Default, as: DefaultSchema
  import ExUnitProperties

  alias Myrmidex.Support.Fixtures.{EctoSchema, EmbeddedSchema, TestPumpkin}

  describe "&GeneratorSchema.generator_schema_impl?/1" do
    test "returns true for implementers" do
      assert GeneratorSchema.implementer?(DefaultSchema)
    end
  end

  describe "&GeneratorSchema.__cast__/3" do
    property "casts any term" do
      check all term <- SD.term() do
        assert %SD{} = GeneratorSchema.__cast__(DefaultSchema, term)
      end
    end

    test "casts ecto schemas into fixed_map generators" do
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, %EctoSchema{})
      assert %{id: int} = pick(stream)
      assert is_integer(int)

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

    test "ignores affixed streams" do
      affixed = Myrmidex.affix(%EctoSchema{}, id: "A")
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, affixed)
      assert %{id: "A"} = pick(stream)

      affixed = Myrmidex.affix_many(%EctoSchema{}, id: "A")
      assert %SD{} = stream = GeneratorSchema.__cast__(DefaultSchema, affixed)
      assert %{id: ["A" | _]} = pick(stream)
    end
  end

  describe "&GeneratorSchema.__cast_field__/3" do
    test "raises usefully when no matching impl" do
      assert_raise Myrmidex.MissingGeneratorError,
                   "Myrmidex.GeneratorSchemas.Default does not define an implementation for &Myrmidex.GeneratorSchema.cast_field/2 for: {:id, :binary_id}",
                   fn -> GeneratorSchema.__cast_field__(DefaultSchema, {:id, :binary_id}, []) end
    end
  end

  describe "&GeneratorSchema.map_fields_to_generators/3" do
    test "maps ecto schema keys to generators" do
      field_generators =
        EctoSchema
        |> GeneratorSchema.to_field_generators(DefaultSchema)
        |> then(&GeneratorSchema.map_fields_to_generators(%EctoSchema{}, &1))

      assert field_generators
             |> Keyword.keys()
             |> MapSet.new()
             |> MapSet.subset?(MapSet.new(Map.keys(%EctoSchema{})))

      assert field_generators
             |> Keyword.values()
             |> Enum.all?(&match?(&1, %SD{}))
    end
  end
end
