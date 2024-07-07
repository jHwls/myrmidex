defmodule Myrmidex.FactoryTest do
  use Myrmidex.Case, async: true
  alias __MODULE__.{TestFactory, TestStreamOnlyFactory}
  alias Myrmidex.Support.Fixtures.EctoSchema

  test "drops autogenerate fields by default" do
    assert Keyword.get(TestFactory.opts(), :drop_autogenerate?)
  end

  test "imports &to_stream/2 and merges module and function opts" do
    assert %{price: _} =
             %EctoSchema{}
             |> TestFactory.to_stream()
             |> Myrmidex.one()

    assert %{"price" => _} =
             %EctoSchema{}
             |> TestFactory.to_stream(attr_keys: :string)
             |> Myrmidex.one()
  end

  test "imports &attrs/3" do
    assert [%{price: price} = attrs, %{price: another_price}] =
             TestFactory.attrs(%EctoSchema{}, 2)

    refute is_struct(attrs)
    assert is_float(price)
    assert is_float(another_price)
    assert price !== another_price
  end

  test "imports &persist/3" do
    assert {:ok, %EctoSchema{}} =
             %EctoSchema{}
             |> TestFactory.to_stream()
             |> TestFactory.persist(%EctoSchema{})
  end

  test "raises usefully when no matching &insert/2 impl" do
    assert_raise RuntimeError,
                 "Myrmidex.FactoryTest.TestStreamOnlyFactory does not define an implementation for Myrmidex.Factory.insert/2",
                 fn ->
                   %EctoSchema{}
                   |> TestStreamOnlyFactory.to_stream()
                   |> TestStreamOnlyFactory.persist(EctoSchema)
                 end
  end

  defmodule TestFactory do
    use Myrmidex.Factory, generator_schema: Myrmidex.GeneratorSchemas.Default
    alias Myrmidex.Support.Fixtures.EctoSchema

    @impl Myrmidex.Factory
    def insert(_module, [attrs]) do
      {:ok, Map.merge(%EctoSchema{}, attrs)}
    end

    def insert(_module, attrs) when is_list(attrs) do
      {length(attrs), Enum.map(attrs, &Map.merge(%EctoSchema{}, &1))}
    end
  end

  defmodule TestStreamOnlyFactory do
    use Myrmidex.Factory, generator_schema: Myrmidex.GeneratorSchemas.Default
  end
end
