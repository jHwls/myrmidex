defmodule Myrmidex.Helpers.EctoSchemaTest do
  use Myrmidex.Support.TestCase, async: true
  alias Myrmidex.Helpers
  alias Myrmidex.Support.Fixtures.{EctoSchema, EmbeddedSchema}

  describe "&Helpers.EctoSchema.ecto_schema_impl?/1" do
    test "identifies behaviour implementers" do
      assert Helpers.EctoSchema.implementer?(EctoSchema)
    end
  end

  describe "&Helpers.EctoSchema.to_normalized_field_types/1" do
    test "returns fields types and tags autogenerates and associations" do
      assert [
               {:id, {:autogenerate, :id}},
               {:extra_id, {:autogenerate, Ecto.UUID}},
               {:inserted_at, {:autogenerate, :utc_datetime_usec}},
               {:symbol_id, {:foreign_key, :id}},
               {:symbol, {:belongs_to, EctoSchema.Parent}},
               {:contract, {:has_one, EctoSchema.Child}},
               {:trades, {:has_many, EctoSchema.Child}},
               {:open_int, :integer},
               {:volume, :integer},
               {:price, :float},
               {:prev_close, :float}
             ] = Helpers.EctoSchema.to_normalized_field_types(EctoSchema)
    end

    test "returns embeds" do
      assert [
               {:date, :date},
               {:time, :time},
               {:preferred_time, :utc_datetime},
               {:valid?, :boolean},
               {
                 :preference,
                 {
                   :parameterized,
                   Ecto.Enum,
                   %{
                     embed_as: :self,
                     mappings: ["🎃": "🎃"],
                     on_cast: %{"🎃" => :"🎃"},
                     on_dump: %{"🎃": "🎃"},
                     on_load: %{"🎃" => :"🎃"},
                     type: :string
                   }
                 }
               },
               {:checkboxes,
                {:parameterized, Ecto.Embedded,
                 %Ecto.Embedded{
                   cardinality: :many,
                   field: :checkboxes,
                   owner: Myrmidex.Support.Fixtures.EmbeddedSchema,
                   related: Myrmidex.Support.Fixtures.EmbeddedSchema.Child
                 }}}
             ] = Helpers.EctoSchema.to_normalized_field_types(EmbeddedSchema)
    end
  end

  describe "&Helpers.EctoSchema.all_field_types/1" do
    test "returns all fields and their types from a schema" do
      assert [
               {:id, :id},
               {:open_int, :integer},
               {:volume, :integer},
               {:price, :float},
               {:prev_close, :float},
               {:extra_id, Ecto.UUID},
               {:inserted_at, :utc_datetime_usec},
               {:symbol_id, :id}
             ] = Helpers.EctoSchema.all_field_types(EctoSchema)
    end
  end

  describe "&Helpers.EctoSchema.all_autogenerate_fields/1" do
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

  describe "&Helpers.EctoSchema.associations_fields/1" do
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
