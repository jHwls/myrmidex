defmodule Myrmidex.Generators do
  @moduledoc """
  Custom and composed generators for use in generator schema modules. These
  generators cover many common cases you might encounter in your codebase. E.g.,
  handling primary key generation:

  ```elixir
  ...

  @impl Myrmidex.GeneratorSchema
  def cast_field({_field, {:autogenerate, type}, _term}, _opts) when is_binary_id_field(type) do
    Myrmidex.Generators.uuid()
  end
  ```

  By default, most generators are configured to allow for narrowing, i.e. use
  in property-based testing. You can, for example, wrap functions in
  `StreamData.unshrinkable/1` to avoid narrowing in other use cases. Or define
  your own generators more suited to your domain in a custom generator schema.

  """
  alias __MODULE__

  @doc """
  Maps binary or bitstring input into matching generators.

  ### Examples

      iex> stream = Myrmidex.Generators.string(<<128>>)
      ...> is_bitstring(Myrmidex.one(stream))
      true

      iex> stream = Myrmidex.Generators.string("catch_all")
      ...> is_binary(Myrmidex.one(stream))
      true

  """
  defdelegate string(string), to: Generators.Binary, as: :string_stream_data

  @doc """
  Generate uuids, e.g. for schema primary keys.

  Per [StreamData docs](`StreamData.repeatedly/1`).

  ### Examples

      iex> stream = Myrmidex.Generators.uuid()
      ...> Ecto.UUID.equal?(Myrmidex.one(stream), Myrmidex.one(stream))
      false

  """
  defdelegate uuid, to: Generators.Binary, as: :uuid_stream_data

  @doc """
  Generate monotonically increasing integer data.

  Useful for ids, although by default ids are only unique per runtime instance:
  i.e. all schemas will share the same sequence of ids. See `counter/2` for
  integer counters unique to a stream.

  Per [StreamData docs](`StreamData.repeatedly/1`).

  ### Examples

      iex> stream = Myrmidex.Generators.monotonic_integer()
      ...> Myrmidex.one(stream) < Myrmidex.one(stream)
      true

  """
  defdelegate monotonic_integer, to: Generators.Number, as: :monotonic_integer_stream_data

  @doc """
  Globally unique streamable counters.

  Useful for ids or other cases where more control over streaming monotonic
  data is needed, e.g., a mock unix timestamp that can be advanced or reversed
  as needed.

  ### Examples

      iex> stream = Myrmidex.Generators.counter(0, 2)
      ...> Myrmidex.many(stream, 4)
      [2, 4, 6, 8]

      iex> stream_1 = Myrmidex.Generators.counter()
      ...> stream_2 = Myrmidex.Generators.counter()
      ...> {Myrmidex.one(stream_1), Myrmidex.one(stream_2)}
      {1, 1}

      iex> start = DateTime.new!(~D[1984-01-01], ~T[00:00:00])
      ...> start_unix = DateTime.to_unix(start)
      ...> stream = Myrmidex.Generators.counter(start_unix, -60)
      ...> Myrmidex.many(stream, 4)
      [441763140, 441763080, 441763020, 441762960]

  """
  defdelegate counter(start \\ 0, step \\ 1), to: Generators.Number, as: :counter_stream_data

  @doc """
  Defaults to current time in utc.

  The default generator for timestamp fields. Can be limited to second precision
  by passing `:utc_datetime` in the `type` argument.

  ### Examples

      iex> stream = Myrmidex.Generators.timestamp()
      ...> DateTime.compare(Myrmidex.one(stream), Myrmidex.one(stream))
      :lt

      iex> stream = Myrmidex.Generators.timestamp(:utc_datetime)
      ...> Myrmidex.one(stream).microsecond
      {0, 0}

  """
  defdelegate timestamp(type \\ :utc_datetime_usec),
    to: Generators.Calendar,
    as: :timestamp_stream_data

  @doc """
  Generate random datetimes, optionally constrained by calendar fields.

  ### Examples

      iex> stream = Myrmidex.Generators.datetime(year: 1984)
      ...> Myrmidex.one(stream).year
      1984

      iex> stream = Myrmidex.Generators.datetime(precision: :second)
      ...> Myrmidex.one(stream).microsecond
      {0, 0}

  ### Options

  This and other calendar generators accept either integers or ranges as option
  values, allowing specific fields to be fixed as constants, or limited to lower
  and upper bounds.

  #{NimbleOptions.docs(Generators.Calendar.schema())}

  """
  defdelegate datetime(opts \\ []), to: Generators.Calendar, as: :datetime_stream_data

  @doc """
  Generate a random date, optionally constrained by date fields.

  See `datetime/1` for available options.

  ### Examples

      iex> stream = Myrmidex.Generators.date(year: 1984)
      ...> Myrmidex.one(stream).year
      1984

  """
  defdelegate date(opts \\ []), to: Generators.Calendar, as: :date_stream_data

  @doc """
  Generate a random time, optionally constrained by `hour`, `minute`, `second`,
  or `microsecond`.

  See `datetime/1` for available options.

  ### Examples

      iex> stream = Myrmidex.Generators.time(hour: 1..9)
      ...> Myrmidex.one(stream).hour < 10
      true

      iex> [hour: 1, minute: 1, second: 1, microsecond: 999999, precision: :millisecond]
      ...> |> Myrmidex.Generators.time()
      ...> |> Myrmidex.one
      ...> |> Time.to_string()
      "01:01:01.999"

  """
  defdelegate time(opts \\ []), to: Generators.Calendar, as: :time_stream_data

  @doc """
  Generate data approximate to a given term. Accepts integers, floats, dates,
  times, and datetimes.

  Generated data is random within the given scale and limits, i.e. not
  characterized by any trend.

  ### Examples

      iex> stream = Myrmidex.Generators.approximate(10, scale: 100)
      ...> int = Myrmidex.one(stream)
      ...> int >= -90 and int <= 110
      true

      iex> stream = Myrmidex.Generators.approximate(Date.utc_today(), limits: [:upper])
      ...> date = Myrmidex.one(stream)
      ...> Date.compare(date, Date.utc_today()) in [:gt, :eq]
      true

  ### Options

  #{NimbleOptions.docs(Generators.Approximate.schema())}

  """
  defdelegate approximate(term, opts \\ []),
    to: Generators.Approximate,
    as: :approximate_stream_data

  @doc """
  Generate data that is quantitavely or chronologically less than or equal to
  the given term.

  See `approximate/2` for details.

  ### Examples

      iex> stream = Myrmidex.Generators.lte(10)
      ...> Myrmidex.one(stream) <= 10
      true

  """
  def lte(term, opts \\ []) do
    approximate(term, Keyword.put(opts, :limits, [:lower]))
  end

  @doc """
  Generate data that is quantitavely or chronologically greater than or equal to
  the given term.

  See `approximate/2` for details.

  ### Examples

      iex> stream = Myrmidex.Generators.gte(10)
      ...> Myrmidex.one(stream) >= 10
      true

  """
  def gte(term, opts \\ []) do
    approximate(term, Keyword.put(opts, :limits, [:upper]))
  end

  @doc """
  Choose one from a (predetermined, limited) list of values.

  Note that this generator is passed via `StreamData.unshrinkable/1` to ensure
  random output.

  ### Examples

      iex> values = ["🐜", "🪰", "🪳"]
      ...> stream = Myrmidex.Generators.enum(values)
      ...> Myrmidex.one(stream) in values
      true

  """
  defdelegate enum(values), to: Generators.Enumerable, as: :enum_stream_data

  @doc """
  Builds a `StreamData.fixed_map/1` generator from an enumerable, optionally
  transforming the keys to strings or atoms.

  ### Examples

      iex> %{id: Myrmidex.Generators.counter()}
      ...> |> Myrmidex.affix(species: "🐜")
      ...> |> Myrmidex.Generators.fixed_map(:string)
      ...> |> Myrmidex.many(3)
      [
        %{"id" => 1, "species" => "🐜"},
        %{"id" => 2, "species" => "🐜"},
        %{"id" => 3, "species" => "🐜"}
      ]

  """
  defdelegate fixed_map(term, keys \\ :atom),
    to: Generators.Enumerable,
    as: :fixed_map_stream_data
end
