defmodule Myrmidex.GeneratorSchema do
  @moduledoc """
  Behaviour defining the contract for a GeneratorSchema module.
    
  """
  alias Myrmidex.Helpers
  alias StreamData, as: SD

  @typedoc "Representation of schema field--type information"
  @type field_type_tuple ::
          {:atom,
           :atom
           | {:atom, :atom}
           | {:parameterized, :atom, map()}}

  @doc "Callback defining custom generator mappings per type"
  @callback cast(term(), opts :: keyword()) :: SD.t(term())

  @doc "Callback defining custom generator mappings per `{field, type}` tuple"
  @callback cast_field(field_type_tuple(), opts :: keyword()) :: SD.t(term())

  @optional_callbacks [cast: 2, cast_field: 2]

  defmacro __using__(_opts) do
    quote do
      @behaviour Myrmidex.GeneratorSchema
      import Myrmidex.GeneratorSchema, only: [generator_schema_fallback: 1]
      alias StreamData, as: SD
    end
  end

  @doc """
  Generates code to delegate to another generator schema in the case of no 
  matching `cast_field/2` implementations. Should be called last in a
  generator schema module.

  """
  defmacro generator_schema_fallback(mod) do
    quote do
      def cast_field(field_type, opts) do
        Myrmidex.GeneratorSchema.__cast_field__(unquote(mod), field_type, opts)
      end
    end
  end

  @doc false
  def __cast__(generator_schema, term, opts \\ [])

  def __cast__(generator_schema, %mod{} = term, opts) do
    mod
    |> to_field_generators(generator_schema, opts)
    |> then(&to_fixed_map_stream_data(term, &1, opts))
  end

  def __cast__(generator_schema, term, opts) when is_atom(term) do
    if Code.ensure_loaded?(term) and Helpers.Struct.implementer?(term) do
      __cast__(generator_schema, term.__struct__(), opts)
    else
      apply(generator_schema, :cast, [term, opts])
    end
  end

  def __cast__(generator_schema, term, opts) do
    apply(generator_schema, :cast, [term, opts])
  end

  @doc false
  def to_field_generators(mod, generator_schema, opts \\ []) do
    if Helpers.EctoSchema.implementer?(mod) do
      mod
      |> Helpers.EctoSchema.build_field_types(opts)
      |> Enum.map(fn {field, _type} = field_type ->
        {field, __cast_field__(generator_schema, field_type, opts)}
      end)
    else
      mod
      |> Helpers.Struct.build_fields_enum()
      |> Enum.map(fn {k, v} ->
        {k, __cast__(generator_schema, v, opts)}
      end)
    end
  end

  @doc false
  def __cast_field__(generator_schema, field_type, opts) do
    apply(generator_schema, :cast_field, [field_type, opts])
  rescue
    e in [FunctionClauseError] ->
      if e.module === generator_schema or implementer?(e.module) do
        reraise Myrmidex.MissingGeneratorError, {generator_schema, field_type}, __STACKTRACE__
      else
        reraise e, __STACKTRACE__
      end
  end

  @doc false
  def implementer?(mod) do
    :attributes
    |> mod.__info__()
    |> Keyword.get(:behaviour, [])
    |> then(&(__MODULE__ in &1))
  end

  @doc false
  def to_fixed_map_stream_data(term, field_generators, opts) do
    term
    |> map_fields_to_generators(field_generators)
    |> maybe_transform_keys(opts[:keys])
    |> Map.new()
    |> SD.fixed_map()
  end

  @doc false
  def map_fields_to_generators(%{} = term, field_generators) do
    term
    |> Map.from_struct()
    |> Enum.reduce([], fn
      {_field, %SD{}} = field_generator, acc ->
        [field_generator | acc]

      {field, _value}, acc ->
        if generator = field_generators[field] do
          [{field, generator} | acc]
        else
          acc
        end
    end)
  end

  @doc false
  def maybe_transform_keys(field_types, nil), do: field_types
  def maybe_transform_keys(field_types, :atom), do: field_types

  def maybe_transform_keys(field_types, type) do
    transform_fn =
      case type do
        :string -> &Atom.to_string/1
      end

    Enum.map(field_types, fn {field, type} -> {transform_fn.(field), type} end)
  end
end
