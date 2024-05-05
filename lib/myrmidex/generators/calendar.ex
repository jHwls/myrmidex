defmodule Myrmidex.Generators.Calendar do
  @moduledoc false
  # DateTime, Date, and Time generators.

  alias Myrmidex.Generators
  alias StreamData, as: SD

  @doc false
  def schema do
    %Date{year: year} = Date.utc_today()

    NimbleOptions.new!(
      year: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 1984..(year + 20),
        type_doc: "`non_neg_integer` or `Range`"
      ],
      month: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 1..12,
        type_doc: "`non_neg_integer` or `Range`"
      ],
      day: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 1..31,
        type_doc: "`non_neg_integer` or `Range`"
      ],
      hour: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 0..23,
        type_doc: "`non_neg_integer` or `Range`"
      ],
      minute: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 0..59,
        type_doc: "`non_neg_integer` or `Range`"
      ],
      second: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 0..59,
        type_doc: "`non_neg_integer` or `Range`"
      ],
      microsecond: [
        type: {:or, [{:struct, Range}, :non_neg_integer]},
        default: 0..999_999,
        type_doc: "`non_neg_integer` or `Range`"
      ],
      precision: [
        type: {:in, [:second, :millisecond, :microsecond]},
        default: :microsecond,
        type_doc: "`:second`, `:millisecond`, or `:microsecond`"
      ]
    )
  end

  defp build_opts!(opts) do
    opts
    |> NimbleOptions.validate!(schema())
    |> maybe_apply_precision()
  end

  defp maybe_apply_precision(opts) do
    case opts[:precision] do
      :second ->
        Keyword.put(opts, :microsecond, nil)

      :millisecond ->
        Keyword.update!(opts, :microsecond, &{&1, 3})

      _ ->
        opts
    end
  end

  defp take_opts(opts, keys), do: Enum.map(keys, &opts[&1])

  defp to_erl_calendar_term!(opts, keys) do
    opts
    |> build_opts!()
    |> take_opts(keys)
    |> List.to_tuple()
  end

  @doc false
  def timestamp_stream_data(:utc_datetime_usec) do
    SD.repeatedly(&DateTime.utc_now/0)
  end

  def timestamp_stream_data(:utc_datetime) do
    SD.repeatedly(fn -> DateTime.utc_now(:second) end)
  end

  @doc false
  def datetime_stream_data(opts) when is_list(opts) do
    opts
    |> to_erl_calendar_term!([:year, :month, :day, :hour, :minute, :second, :microsecond])
    |> datetime_stream_data()
  end

  def datetime_stream_data({year, month, day, hour, minute, second, microsecond}) do
    {
      date_stream_data({year, month, day}),
      time_stream_data({hour, minute, second, microsecond})
    }
    |> SD.bind(fn {date, time} ->
      SD.constant(DateTime.new!(date, time))
    end)
  end

  @doc false
  def date_stream_data(opts) when is_list(opts) do
    opts
    |> to_erl_calendar_term!([:year, :month, :day])
    |> date_stream_data()
  end

  def date_stream_data({year, month, day}) do
    {
      Generators.Number.integer_stream_data(year),
      Generators.Number.integer_stream_data(month)
    }
    |> SD.bind(fn {year, month} ->
      {
        SD.constant(year),
        SD.constant(month),
        day_stream_data(day, month, year)
      }
    end)
    |> SD.bind(fn {year, month, day} ->
      SD.repeatedly(fn ->
        Date.new!(year, month, day)
      end)
    end)
  end

  @doc false
  def day_stream_data(%Range{last: last} = day, month, year) do
    last =
      year
      |> Date.new!(month, 1)
      |> Date.days_in_month()
      |> min(last)

    Generators.Number.integer_stream_data(%Range{day | last: last})
  end

  @doc false
  def time_stream_data(opts) when is_list(opts) do
    opts
    |> to_erl_calendar_term!([:hour, :minute, :second, :microsecond])
    |> time_stream_data()
  end

  def time_stream_data({hour, minute, second, microsecond}) do
    {
      Generators.Number.integer_stream_data(hour),
      Generators.Number.integer_stream_data(minute),
      Generators.Number.integer_stream_data(second),
      microsecond_stream_data(microsecond)
    }
    |> SD.bind(fn
      {hour, minute, second, nil} ->
        SD.repeatedly(fn -> Time.new!(hour, minute, second) end)

      {hour, minute, second, microsecond} ->
        SD.repeatedly(fn -> Time.new!(hour, minute, second, microsecond) end)
    end)
  end

  @doc false
  def microsecond_stream_data(nil), do: SD.constant(nil)

  def microsecond_stream_data({microsecond, precision}) do
    {Generators.Number.integer_stream_data(microsecond), SD.constant(precision)}
  end

  def microsecond_stream_data(microsecond) do
    Generators.Number.integer_stream_data(microsecond)
  end
end
