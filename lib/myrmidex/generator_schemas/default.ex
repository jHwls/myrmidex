defmodule Myrmidex.GeneratorSchemas.Default do
  @moduledoc """
  The default/fallback implementation of a `Myrmidex.GeneratorSchema`.

  Defines sensible generators for basic Elixir terms and common structs. Also
  provides basic handling of Ecto fields for generating schemas.

  """
  use Myrmidex.GeneratorSchema
  alias Myrmidex.Generators

  defguardp is_binary_id_field(type) when type in [:binary_id, Ecto.UUID]
  defguardp is_datetime_field(type) when type in [:utc_datetime_usec, :utc_datetime]
  defguardp is_ecto_assoc(assoc) when assoc in [:has_one, :belongs_to, :has_many, :foreign_key]

  @impl Myrmidex.GeneratorSchema
  def cast_field({_field, {:autogenerate, :id}, _term}, _opts) do
    id_generator()
  end

  def cast_field({_field, {:autogenerate, type}, _term}, _opts) when is_binary_id_field(type) do
    binary_id_generator()
  end

  def cast_field({_field, {:autogenerate, type}, _term}, _opts) when is_datetime_field(type) do
    timestamp_generator(type)
  end

  def cast_field({_field, {:parameterized, {Ecto.Embedded, %Ecto.Embedded{}}}, _term}, _opts) do
    nil_generator()
  end

  # For compatibility with Ecto < 3.12
  # https://github.com/elixir-ecto/ecto/blob/4f0c990019ee5b5d96721958e226519c2a6ee83f/CHANGELOG.md?plain=1#L81
  def cast_field({_field, {:parameterized, Ecto.Embedded, %Ecto.Embedded{}}, _term}, _opts) do
    nil_generator()
  end

  def cast_field({_field, {:parameterized, {Ecto.Enum, %{mappings: mappings}}}, _term}, _opts) do
    mappings
    |> Keyword.keys()
    |> enum_generator()
  end

  # For compatibility with Ecto < 3.12
  # https://github.com/elixir-ecto/ecto/blob/4f0c990019ee5b5d96721958e226519c2a6ee83f/CHANGELOG.md?plain=1#L81
  def cast_field({_field, {:parameterized, Ecto.Enum, %{mappings: mappings}}, _term}, _opts) do
    mappings
    |> Keyword.keys()
    |> enum_generator()
  end

  def cast_field({_field, {assoc, _type}, _term}, _opts) when is_ecto_assoc(assoc) do
    nil_generator()
  end

  def cast_field({_field, type, _term}, _opts) when is_datetime_field(type) do
    datetime_generator(type)
  end

  def cast_field({_field, :date, _term}, _opts), do: date_generator()
  def cast_field({_field, :time, _term}, _opts), do: time_generator()
  def cast_field({_field, :integer, _term}, _opts), do: integer_generator()
  def cast_field({_field, :float, _term}, _opts), do: float_generator()
  def cast_field({_field, :boolean, _term}, _opts), do: boolean_generator()
  def cast_field({_field, :string, _term}, _opts), do: string_generator()
  def cast_field({_field, term}, opts), do: cast(term, opts)

  @impl Myrmidex.GeneratorSchema
  def cast(nil, _opts), do: nil_generator()
  def cast(%Date{} = _term, _opts), do: date_generator()
  def cast(%Time{} = _term, _opts), do: time_generator()
  def cast(%DateTime{} = _term, _opts), do: datetime_generator(:utc_datetime_usec)
  def cast(%{} = _term, _opts), do: empty_map_generator()
  def cast(term, _opts) when term === [], do: empty_list_generator()
  def cast(term, opts) when is_list(term), do: list_generator(term, opts)
  def cast(term, _opts) when is_binary(term), do: string_generator(term)
  def cast(term, _opts) when is_boolean(term), do: boolean_generator()
  def cast(term, _opts) when is_integer(term), do: integer_generator()
  def cast(term, _opts) when is_float(term), do: float_generator()
  def cast(term, _opts) when is_atom(term), do: atom_generator()
  def cast(term, _opts) when is_reference(term), do: ref_generator()
  def cast(term, opts) when is_tuple(term), do: tuple_generator(term, opts)

  defdelegate binary_id_generator(), to: Generators, as: :uuid
  defdelegate date_generator, to: Generators, as: :date
  defdelegate enum_generator(values), to: Generators, as: :enum
  defdelegate id_generator, to: Generators, as: :monotonic_integer
  defdelegate string_generator(term), to: Generators, as: :string
  defdelegate time_generator, to: Generators, as: :time
  defdelegate timestamp_generator(type), to: Generators, as: :timestamp

  def datetime_generator(:utc_datetime) do
    Generators.datetime(precision: :second)
  end

  def datetime_generator(:utc_datetime_usec) do
    Generators.datetime()
  end

  def atom_generator, do: SD.atom(:alphanumeric)
  def boolean_generator, do: SD.boolean()
  def empty_list_generator, do: SD.constant([])
  def empty_map_generator, do: SD.constant(%{})
  def float_generator, do: SD.float()
  def integer_generator, do: SD.integer()
  def nil_generator, do: SD.constant(nil)
  def ref_generator, do: SD.repeatedly(&make_ref/0)
  def string_generator, do: SD.string(:alphanumeric)

  @doc """
  For non-empty lists, generates a list of terms representative of the original
  list items.

  """
  def list_generator(list, opts) do
    list
    |> Stream.map(&cast(&1, opts))
    |> Enum.uniq()
    |> SD.one_of()
    |> then(&SD.list_of(&1))
  end

  @doc "Generates tuples of the same size and terms as the passed tuple."
  def tuple_generator(tuple, opts) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&cast(&1, opts))
    |> List.to_tuple()
    |> then(&SD.tuple(&1))
  end
end
