defmodule Myrmidex.GeneratorSchema do
  @moduledoc """
  Behaviour defining the contract for a GeneratorSchema module.

  GeneratorSchemas map terms, or [fields](`Myrmidex.Field`) defining the types
  of map or struct fields, into StreamData generators. See `Myrmidex.GeneratorSchemas.Default`.

  """
  alias Myrmidex.{Field, Helpers}
  alias StreamData, as: SD
  import Field, only: [is_field: 1]

  @doc "Callback defining custom generator mappings per term"
  @callback cast(term(), opts :: keyword()) :: SD.t(term())

  @doc "Callback defining custom generator mappings per field--type tuple"
  @callback cast_field(Field.t(), opts :: keyword()) :: SD.t(term())

  @optional_callbacks [cast: 2, cast_field: 2]

  defmacro __using__(_opts) do
    quote do
      @behaviour Myrmidex.GeneratorSchema
      import Myrmidex.GeneratorSchema, only: [generator_schema_fallback: 1]
      alias StreamData, as: SD
    end
  end

  @doc false
  def implementer?(mod) do
    :attributes
    |> mod.__info__()
    |> Keyword.get(:behaviour, [])
    |> then(&(__MODULE__ in &1))
  end

  @doc """
  Generates code to delegate to another generator schema in the case of no
  matching `c:cast_field/2` implementations. Should be called last in a generator
  schema module.

  """
  defmacro generator_schema_fallback(mod) do
    quote do
      def cast_field(field_tuple, opts) do
        Myrmidex.GeneratorSchema.__cast_field__(unquote(mod), field_tuple, opts)
      end

      def cast(term, opts) do
        Myrmidex.GeneratorSchema.__cast__(unquote(mod), term, opts)
      end
    end
  end

  @doc false
  def __cast__(generator_schema, term, opts \\ [])

  def __cast__(generator_schema, %_mod{} = term, opts) do
    build_fixed_map_generator(generator_schema, term, opts)
  end

  def __cast__(generator_schema, term, opts) when is_map(term) do
    if atom_or_string_keyed?(term) do
      build_fixed_map_generator(generator_schema, term, opts)
    else
      cast_and_build_generator(generator_schema, term, opts)
    end
  end

  def __cast__(generator_schema, term, opts) when is_atom(term) do
    if Code.ensure_loaded?(term) and Helpers.Struct.implementer?(term) do
      __cast__(generator_schema, term.__struct__(), opts)
    else
      cast_and_build_generator(generator_schema, term, opts)
    end
  end

  def __cast__(generator_schema, term, opts) do
    cast_and_build_generator(generator_schema, term, opts)
  end

  defp atom_or_string_keyed?(%{} = term) do
    term
    |> Map.keys()
    |> Enum.all?(&(is_binary(&1) or is_atom(&1)))
  end

  defp build_fixed_map_generator(generator_schema, term, opts) do
    term
    |> to_field_generator_tuple_stream(generator_schema, opts)
    |> Helpers.StreamData.fixed_map_stream_data(opts[:attr_keys])
  end

  defp cast_and_build_generator(generator_schema, term, opts) do
    generator_schema
    |> apply(:cast, [term, opts])
    |> build_generator(term, opts)
  end

  defp build_generator(%SD{} = generator, term, opts) do
    cond do
      opts[:limit_generation?] ->
        SD.constant(term)

      true ->
        generator
    end
  end

  @doc false
  def __cast_field__(generator_schema, field_tuple, opts) do
    cast_field_and_build_generator(generator_schema, field_tuple, opts)
  rescue
    e in [FunctionClauseError] ->
      maybe_raise_missing_generator_error(
        e,
        generator_schema,
        [field_tuple, opts],
        __STACKTRACE__
      )
  end

  defp cast_field_and_build_generator(generator_schema, field_tuple, opts) do
    case Field.term(field_tuple) do
      %{} = map when not is_struct(map) ->
        __cast__(generator_schema, map, opts)

      term ->
        generator_schema
        |> apply(:cast_field, [field_tuple, opts])
        |> build_generator(term, opts)
    end
  end

  defp maybe_raise_missing_generator_error(e, generator_schema, args, stacktrace) do
    if e.module === generator_schema or implementer?(e.module) do
      reraise Myrmidex.MissingGeneratorError, Map.update!(e, :args, &(&1 || args)), stacktrace
    else
      reraise e, stacktrace
    end
  end

  defguard is_mappable(term) when is_map(term) or is_list(term)

  @doc false
  def to_field_generator_tuple_stream(%mod{} = term, generator_schema, opts) do
    if Helpers.EctoSchema.implementer?(mod) do
      term
      |> Helpers.EctoSchema.build_field_type_term_tuples(opts)
      |> to_field_generator_tuple_stream(generator_schema, opts)
    else
      term
      |> Map.from_struct()
      |> to_field_generator_tuple_stream(generator_schema, opts)
    end
  end

  def to_field_generator_tuple_stream(term, generator_schema, opts)
      when is_mappable(term) do
    term
    |> Stream.map(&{&1, generator_schema, opts})
    |> Stream.map(&to_field_generator_tuple/1)
  end

  defp to_field_generator_tuple({{field, _type, %SD{} = generator}, _generator_schema, _opts}) do
    {field, generator}
  end

  defp to_field_generator_tuple({{field, %SD{} = generator}, _generator_schema, _opts}) do
    {field, generator}
  end

  defp to_field_generator_tuple({field_tuple, generator_schema, opts})
       when is_field(field_tuple) do
    {Field.name(field_tuple), __cast_field__(generator_schema, field_tuple, opts)}
  end
end
