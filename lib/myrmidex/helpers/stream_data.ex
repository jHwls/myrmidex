defmodule Myrmidex.Helpers.StreamData do
  @moduledoc """
  General use generators for use in generator schema modules.

  By default, these generators are configured to allow for narrowing, i.e.
  use in property-based testing. You can, for example, wrap functions in 
  `StreamData.unshrinkable/1`, or define your own more suited to your domain,
  in a custom generator schema.

  """
  alias StreamData, as: SD

  @doc """
  Per [StreamData docs](`StreamData.repeatedly/1`).  Useful for ids, although by
  default ids are only unique per runtime instance: i.e. all schemas will share
  the same sequence of ids.

  More sophisticated id generators can be implemented via generator schemas.
    
  """
  def monotonic_integer_stream_data do
    SD.repeatedly(fn -> System.unique_integer([:positive, :monotonic]) end)
  end

  @doc """
  Per [StreamData docs](`StreamData.repeatedly/1`). 
    
  """
  def uuid_stream_data do
    SD.repeatedly(&Ecto.UUID.autogenerate/0)
  end

  @doc """
  Defaults to current time in utc. The default generator for timestamp fields.

  ### Examples

      iex> stream = Myrmidex.Helpers.StreamData.timestamp_stream_data()         
      iex> match?(%DateTime{}, Myrmidex.one(stream))
      true

      iex> stream = Myrmidex.Helpers.StreamData.timestamp_stream_data(:utc_datetime)
      iex> match?(%DateTime{microsecond: {0,0}}, Myrmidex.one(stream))
      true

  """
  def timestamp_stream_data(type \\ :utc_datetime_usec)

  def timestamp_stream_data(:utc_datetime_usec) do
    SD.constant(now())
  end

  def timestamp_stream_data(:utc_datetime) do
    SD.constant(DateTime.truncate(now(), :second))
  end

  defp now, do: DateTime.utc_now()

  @doc """
  Choose one from a (predetermined, limited) list of values. Note that this 
  generator is passed via [unshrinkable](`StreamData.unshrinkable/1`) to
  ensure random output.
    
  ### Examples

      iex> values = ["🐜", "🪰", "🪳"]
      iex> stream = Myrmidex.Helpers.StreamData.enum_stream_data(values)
      iex> Myrmidex.one(stream) in values
      true

  """
  def enum_stream_data([_ | _] = values) do
    values
    |> SD.member_of()
    |> SD.unshrinkable()
  end

  @doc false
  def datetime_stream_data(type \\ :utc_datetime_usec)

  def datetime_stream_data(:utc_datetime_usec) do
    {
      date_stream_data(),
      time_stream_data()
    }
    |> SD.bind(fn {date, time} ->
      SD.repeatedly(fn -> DateTime.new!(date, time) end)
    end)
  end

  def datetime_stream_data(:utc_datetime) do
    SD.bind(datetime_stream_data(), fn datetime ->
      SD.repeatedly(fn -> DateTime.truncate(datetime, :second) end)
    end)
  end

  @doc """
  Generate a random date, optionally constrained before or after a given date.

  ### Options
  TODO: Not implemented yet.

  """
  def date_stream_data(_opts \\ []) do
    %Date{year: year} = _today = Date.utc_today()

    {
      SD.integer(1984..(year + 20)),
      SD.integer(1..12)
    }
    |> SD.tuple()
    |> SD.bind(fn {yr, mo} ->
      {
        SD.constant(yr),
        SD.constant(mo),
        SD.integer(1..days_in_month(yr, mo))
      }
    end)
    |> SD.bind(fn {yr, mo, da} ->
      SD.repeatedly(fn ->
        Date.new!(yr, mo, da)
      end)
    end)
  end

  defp days_in_month(year, month) do
    year
    |> Date.new!(month, 1)
    |> Date.days_in_month()
  end

  @doc """
  Generate a random time.
    
  """
  def time_stream_data(opts \\ []) do
    opts =
      Keyword.merge(
        [
          hour: 0..23,
          minute: 0..59,
          second: 0..59,
          microsecond: 0..999_999
        ],
        opts
      )

    {
      integer_stream_data(opts[:hour]),
      integer_stream_data(opts[:minute]),
      integer_stream_data(opts[:second]),
      integer_stream_data(opts[:microsecond])
    }
    |> SD.tuple()
    |> SD.bind(fn {hour, min, sec, microsec} ->
      SD.repeatedly(fn -> Time.new!(hour, min, sec, microsec) end)
    end)
  end

  @doc """
  Generate integers. Given a single integer, produces a constant stream
  of that value: this is useful when composing other generators, e.g.
  `&time_stream_data/1`.

  ### Examples

      iex> stream = Myrmidex.Helpers.StreamData.integer_stream_data()
      iex> is_integer(Myrmidex.one(stream))
      true
     
  """
  def integer_stream_data, do: SD.integer()
  def integer_stream_data(int) when is_integer(int), do: SD.constant(int)

  @doc """
  Constrain integers generated to a given range.

  """
  def integer_stream_data(%Range{} = range), do: SD.integer(range)

  @doc """
  Maps binary or bitstring input into (arbitrary) matching generation ranges.

  Mainly logical re: making the docs :) Can be replaced with your own
  implementation with a `Myrmidex.GeneratorSchema`.

  ### Examples

      iex> stream = Myrmidex.Helpers.StreamData.string_stream_data(<<128>>)
      iex> is_bitstring(Myrmidex.one(stream))
      true

      iex> stream = Myrmidex.Helpers.StreamData.string_stream_data("catch_all")
      iex> is_binary(Myrmidex.one(stream))
      true

  """
  def string_stream_data(string) when is_binary(string) do
    cond do
      !String.printable?(string) ->
        SD.bitstring()

      String.length(string) === 1 ->
        string
        |> String.to_charlist()
        |> List.first()
        |> string_stream_data()

      Regex.match?(~r/^[[:alpha:]]*$/, string) ->
        SD.string([?a..?z, ?A..?Z])

      Regex.match?(~r/^[[:alnum:]]+$/, string) ->
        SD.string(:alphanumeric)

      true ->
        SD.string(:utf8)
    end
  end

  def string_stream_data(char) when is_integer(char) do
    char
    |> ascii_range()
    |> SD.string(length: 1)
  end

  @animoji_ascii_range 128_000..128_048
  @food_ascii_range 127_812..127_884
  defp ascii_range(char) do
    cond do
      char in @animoji_ascii_range -> @animoji_ascii_range
      char in @food_ascii_range -> @food_ascii_range
      true -> :ascii
    end
  end
end
