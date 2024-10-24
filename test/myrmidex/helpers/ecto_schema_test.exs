defmodule Myrmidex.Helpers.EctoSchemaTest do
  use Myrmidex.Case, async: true
  alias Myrmidex.Helpers
  alias Myrmidex.Support.Fixtures.{EctoSchema, EmbeddedSchema}

  describe "Helpers.EctoSchema.implementer?/1" do
    test "identifies implementer modules" do
      assert Helpers.EctoSchema.implementer?(EctoSchema)
    end

    test "identifies implementer structs" do
      assert Helpers.EctoSchema.implementer?(%EctoSchema{})
    end
  end

  describe "Helpers.EctoSchema.build_field_type_term_tuples/2" do
    @opts []

    defp refute_field_in_tuples(field_type_term_tuples, field) do
      refute Enum.find(field_type_term_tuples, &(elem(&1, 1) === field))
    end

    test "introspects Ecto schemas" do
      assert [
               {:id, {:autogenerate, :id}, nil},
               {:extra_id, {:autogenerate, Ecto.UUID}, nil},
               {:inserted_at, {:autogenerate, :utc_datetime_usec}, nil},
               {:symbol_id, {:foreign_key, :id}, nil},
               {:symbol, {:belongs_to, EctoSchema.Parent}, %Ecto.Association.NotLoaded{}},
               {:contract, {:has_one, EctoSchema.Child}, %Ecto.Association.NotLoaded{}},
               {:trades, {:has_many, EctoSchema.Child}, %Ecto.Association.NotLoaded{}},
               {:open_int, :integer, nil},
               {:volume, :integer, nil},
               {:price, :float, 1.0},
               {:prev_close, :float, nil}
             ] = Helpers.EctoSchema.build_field_type_term_tuples(%EctoSchema{}, @opts)
    end

    test "introspects Ecto embedded schemas" do
      assert [
               {:date, :date, nil},
               {:time, :time, nil},
               {:preferred_time, :utc_datetime, nil},
               {:valid?, :boolean, nil},
               {
                 :preference,
                 {
                   :parameterized,
                   {Ecto.Enum,
                    %{
                      embed_as: :self,
                      mappings: ["🎃": "🎃"],
                      on_cast: %{"🎃" => :"🎃"},
                      on_dump: %{"🎃": "🎃"},
                      on_load: %{"🎃" => :"🎃"},
                      type: :string
                    }}
                 },
                 nil
               },
               {:checkboxes,
                {:parameterized,
                 {Ecto.Embedded,
                  %Ecto.Embedded{
                    cardinality: :many,
                    field: :checkboxes,
                    owner: Myrmidex.Support.Fixtures.EmbeddedSchema,
                    related: Myrmidex.Support.Fixtures.EmbeddedSchema.Child
                  }}}, []}
             ] = Helpers.EctoSchema.build_field_type_term_tuples(%EmbeddedSchema{}, [])
    end

    @opts [drop_autogenerate?: true]
    test "optionally omits autogenerated fields" do
      field_type_term_tuples =
        Helpers.EctoSchema.build_field_type_term_tuples(%EctoSchema{}, @opts)

      refute_field_in_tuples(field_type_term_tuples, :id)
      refute_field_in_tuples(field_type_term_tuples, :extra_id)
      refute_field_in_tuples(field_type_term_tuples, :inserted_at)
    end

    @opts [drop_associations?: true]
    test "optionally omits association fields" do
      field_type_term_tuples =
        Helpers.EctoSchema.build_field_type_term_tuples(%EctoSchema{}, @opts)

      refute_field_in_tuples(field_type_term_tuples, :symbol)
      refute_field_in_tuples(field_type_term_tuples, :contract)
      refute_field_in_tuples(field_type_term_tuples, :trades)
    end
  end

  describe "Helpers.EctoSchema.all_autogenerate_fields/1" do
    test "extracts id and autogenerate fields" do
      assert [
               {:id, :id, :id},
               {
                 :extra_id,
                 {Ecto.UUID, :autogenerate, []}
               },
               {:inserted_at, {Ecto.Schema, :__timestamps__, [:utc_datetime_usec]}}
             ] = Helpers.EctoSchema.all_autogenerate_fields(EctoSchema)
    end
  end

  describe "Helpers.EctoSchema.associations_fields/1" do
    test "extracts associations fields" do
      assert [
               {:symbol,
                %Ecto.Association.BelongsTo{
                  cardinality: :one,
                  field: :symbol,
                  owner: EctoSchema,
                  related: EctoSchema.Parent,
                  owner_key: :symbol_id,
                  related_key: :id,
                  relationship: :parent
                }},
               {:contract,
                %Ecto.Association.Has{
                  cardinality: :one,
                  field: :contract,
                  owner: EctoSchema,
                  related: EctoSchema.Child,
                  owner_key: :id,
                  related_key: :ecto_schema_id,
                  relationship: :child
                }},
               {:trades,
                %Ecto.Association.Has{
                  cardinality: :many,
                  field: :trades,
                  owner: EctoSchema,
                  related: EctoSchema.Child,
                  owner_key: :id,
                  related_key: :ecto_schema_id,
                  relationship: :child
                }}
             ] = Helpers.EctoSchema.associations_fields(EctoSchema)
    end
  end
end
