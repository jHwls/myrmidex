defmodule Myrmidex.Helpers.EctoSchema do
  @moduledoc false

  @doc false
  def implementer?(%mod{}), do: implementer?(mod)

  def implementer?(mod) do
    :functions
    |> mod.__info__()
    |> then(&({:__schema__, 1} in &1))
  end

  @doc false
  def build_field_type_term_tuples(%mod{} = schema, opts) do
    mod
    |> introspect_field_type_tuples()
    |> zip_with_terms(schema)
    |> maybe_drop_schema_fields(opts)
  end

  @doc false
  def introspect_field_type_tuples(mod) do
    autogen_fields =
      mod
      |> all_autogenerate_fields()
      |> normalized_autogenerate_fields()

    assoc_fields =
      mod
      |> associations_fields()
      |> normalized_associations_fields()

    assoc_autogen_fields = autogen_fields ++ assoc_fields

    rest =
      mod
      |> fields()
      |> Kernel.--(field_names(assoc_autogen_fields))
      |> Enum.map(&{&1, field_type(mod, &1)})

    assoc_autogen_fields ++ rest
  end

  defp normalized_autogenerate_fields(field_types) do
    Enum.map(field_types, fn
      {field, {_, :__timestamps__, [type]}} ->
        {field, {:autogenerate, type}}

      {field, _schema_field, type} ->
        {field, {:autogenerate, type}}

      {field, {type, :autogenerate, _opts}} ->
        {field, {:autogenerate, type}}
    end)
  end

  defp normalized_associations_fields(field_types) do
    field_types
    |> Enum.map(fn {field, assoc} ->
      case assoc do
        %Ecto.Association.BelongsTo{
          field: ^field,
          cardinality: :one,
          relationship: :parent,
          owner_key: owner_key,
          related: related,
          related_key: related_key
        } ->
          [
            {owner_key, {:foreign_key, field_type(related, related_key)}},
            {field, {:belongs_to, related}}
          ]

        %Ecto.Association.Has{
          field: ^field,
          cardinality: :one,
          relationship: :child,
          related: related
        } ->
          {field, {:has_one, related}}

        %Ecto.Association.Has{
          field: ^field,
          cardinality: :many,
          relationship: :child,
          related: related
        } ->
          {field, {:has_many, related}}
      end
    end)
    |> List.flatten()
  end

  @doc false
  def zip_with_terms(field_type_tuples, schema) do
    Enum.map(field_type_tuples, fn {field, type} = _field_type_tuple ->
      {field, type, Map.get(schema, field)}
    end)
  end

  @doc false
  def maybe_drop_schema_fields(fields, opts) do
    Enum.reject(fields, fn
      {_field, _type, %StreamData{}} ->
        false

      {_field, {:autogenerate, _type}, _term} ->
        Keyword.get(opts, :drop_autogenerate?)

      {_field, {assoc, _type}, _term}
      when assoc in [:foreign_key, :belongs_to, :has_one, :has_many] ->
        Keyword.get(opts, :drop_associations?)

      _field_type_tuple ->
        false
    end)
  end

  defp field_names(field_type_tuples) do
    Enum.map(field_type_tuples, &elem(&1, 0))
  end

  @doc false
  def all_autogenerate_fields(mod) do
    autogenerate_fields = autogenerate_fields(mod)

    case autogenerate_id_field(mod) do
      nil ->
        autogenerate_fields

      id_field ->
        [id_field | autogenerate_fields]
    end
  end

  @doc false
  def autogenerate_fields(mod) do
    :autogenerate
    |> mod.__schema__()
    |> Enum.map(fn
      {[_ | _] = fields, type} ->
        Enum.map(fields, &{&1, type})
    end)
    |> List.flatten()
  end

  @doc false
  def autogenerate_id_field(mod) do
    mod.__schema__(:autogenerate_id)
  end

  @doc false
  def associations_fields(mod) do
    :associations
    |> mod.__schema__()
    |> Enum.map(&association_field(mod, &1))
  end

  @doc false
  def association_field(mod, field) do
    {field, mod.__schema__(:association, field)}
  end

  @doc false
  def fields(mod) do
    mod.__schema__(:fields)
  end

  @doc false
  def field_type(mod, field) do
    mod.__schema__(:type, field)
  end
end
