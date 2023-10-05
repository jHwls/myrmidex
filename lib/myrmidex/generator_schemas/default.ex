defmodule Myrmidex.GeneratorSchemas.Default do
  @moduledoc """
  The default/fallback implementation of a `Myrmidex.GeneratorSchema`.

  """
  use Myrmidex.GeneratorSchema
  alias Myrmidex.Helpers.StreamData, as: SDHelpers

  defguardp is_binary_id_field(type) when type in [:binary_id, Ecto.UUID]
  defguardp is_datetime_field(type) when type in [:utc_datetime_usec, :utc_datetime]

  @impl Myrmidex.GeneratorSchema
  def cast_field({_field, {:autogenerate, :id}}, _opts),
    do: SDHelpers.monotonic_integer_stream_data()

  def cast_field({_field, {:autogenerate, type}}, _opts) when is_binary_id_field(type),
    do: SDHelpers.uuid_stream_data()

  def cast_field({_field, {:autogenerate, type}}, _opts) when is_datetime_field(type),
    do: SDHelpers.timestamp_stream_data(type)

  def cast_field({_field, {:parameterized, Ecto.Embedded, %Ecto.Embedded{}}}, _opts),
    do: SD.constant(nil)

  def cast_field({_field, {:parameterized, Ecto.Enum, %{mappings: mappings}}}, _opts) do
    mappings
    |> Keyword.keys()
    |> SDHelpers.enum_stream_data()
  end

  def cast_field({_field, {assoc, _type}}, _opts)
      when assoc in [:has_one, :belongs_to, :has_many, :foreign_key],
      do: SD.constant(nil)

  def cast_field({_field, type}, _opts) when is_datetime_field(type),
    do: SDHelpers.datetime_stream_data(type)

  def cast_field({_field, :date}, _opts),
    do: SDHelpers.date_stream_data()

  def cast_field({_field, :time}, _opts),
    do: SDHelpers.time_stream_data()

  def cast_field({_field, :integer}, _opts), do: SD.integer()
  def cast_field({_field, :float}, _opts), do: SD.float()
  def cast_field({_field, :string}, _opts), do: SD.string(:alphanumeric)
  def cast_field({_field, :boolean}, _opts), do: SD.boolean()

  @impl Myrmidex.GeneratorSchema
  def cast(term, _opts) when is_map(term) and term === %{} do
    SD.map_of(SD.atom(:alphanumeric), SD.term())
  end

  def cast(term, opts) when is_map(term) do
    {k, v} = Enum.at(term, 0)
    SD.map_of(cast(k, opts), cast(v, opts))
  end

  def cast(term, _opts) when is_list(term),
    do: SD.list_of(SD.term())

  def cast(term, opts) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> Enum.map(&cast(&1, opts))
    |> List.to_tuple()
    |> SD.tuple()
  end

  def cast(term, _opts) when is_binary(term),
    do: SDHelpers.string_stream_data(term)

  def cast(term, _opts) when is_boolean(term),
    do: SD.boolean()

  def cast(term, _opts) when is_integer(term),
    do: SD.integer()

  def cast(term, _opts) when is_float(term),
    do: SD.float()

  def cast(term, _opts) when is_atom(term),
    do: SD.atom(:alphanumeric)

  def cast(term, _opts) when is_reference(term),
    do: SD.constant(make_ref())
end
