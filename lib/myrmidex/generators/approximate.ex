defmodule Myrmidex.Generators.Approximate do
  @moduledoc false
  # Generators for data approximate to a given term.

  alias Myrmidex.{Generators, Helpers}
  alias StreamData, as: SD

  @schema NimbleOptions.new!(
            scale: [
              type: {:or, [:pos_integer, :float, {:tuple, [:atom, :pos_integer]}]},
              default: 1,
              doc: "The minimum proximity to (maximum distance from) the term.",
              type_doc: "`pos_integer`, `float`, or `{atom, :pos_integer}`"
            ],
            limits: [
              type: {:list, {:in, [:lower, :upper]}},
              default: [:lower, :upper],
              doc: "Controls the range of generation in relation to the term.",
              type_doc: "`non_neg_integer` or `Range`"
            ]
          )

  @doc false
  def schema, do: @schema

  defp build_opts!(opts, default_opts) do
    default_opts
    |> Keyword.merge(opts)
    |> NimbleOptions.validate!(@schema)
  end

  @doc false
  def approximate_stream_data!(term, opts) when is_integer(term) do
    opts = build_opts!(opts, scale: term)

    term
    |> build_limits(opts)
    |> SD.integer()
  end

  def approximate_stream_data!(term, opts) when is_float(term) do
    opts = build_opts!(opts, scale: term)

    term
    |> float_opts(opts)
    |> SD.float()
  end

  def approximate_stream_data!(%DateTime{} = term, opts) do
    opts = build_opts!(opts, scale: {:second, 60})

    term
    |> erl_calendar_limits(opts)
    |> Generators.Calendar.datetime_stream_data()
  end

  def approximate_stream_data!(%Date{} = term, opts) do
    opts = build_opts!(opts, scale: 7)

    term
    |> erl_calendar_limits(opts)
    |> Generators.Calendar.date_stream_data()
  end

  def approximate_stream_data!(%Time{} = term, opts) do
    opts = build_opts!(opts, scale: {:second, 60})

    term
    |> erl_calendar_limits(opts)
    |> Generators.Calendar.time_stream_data()
  end

  def approximate_stream_data!(term, opts) do
    if Helpers.StreamData.stream_data?(term) do
      SD.bind(term, fn term -> approximate_stream_data!(term, opts) end)
    else
      raise ArgumentError,
        message:
          "first argument must be integer, float, Date, Time, or DateTime, or stream data that produces one of these terms: #{inspect(term)}"
    end
  end

  defp float_opts(float, opts) do
    {lower, upper} = build_limits(float, opts)
    [min: lower, max: upper]
  end

  defp build_limits(limit_fun, term, opts) when is_function(limit_fun) do
    {lower_limit(limit_fun, term, opts), upper_limit(limit_fun, term, opts)}
  end

  defp build_limits(term, opts) when is_float(term) do
    build_limits(&Kernel.+/2, term, opts)
  end

  defp build_limits(term, opts) when is_integer(term) do
    limit_fun = fn term, modifier ->
      ceil(term + modifier)
    end

    {lower, upper} = build_limits(limit_fun, term, opts)
    lower..upper
  end

  defp upper_limit(limit_fun, term, opts) do
    if :upper in opts[:limits] do
      limit(limit_fun, term, 1, opts[:scale])
    else
      term
    end
  end

  defp lower_limit(limit_fun, term, opts) do
    if :lower in opts[:limits] do
      limit(limit_fun, term, -1, opts[:scale])
    else
      term
    end
  end

  defp limit(limit_fun, term, modifier, {unit, scale}) do
    limit_fun.(term, {unit, modifier * scale})
  end

  defp limit(limit_fun, term, modifier, scale) do
    limit_fun.(term, modifier * scale)
  end

  defp erl_calendar_limits(%mod{} = term, opts) do
    limit_fun =
      case mod do
        DateTime ->
          fn %DateTime{} = term, {unit, scale} ->
            DateTime.add(term, scale, unit)
          end

        Date ->
          fn %Date{} = term, scale ->
            Date.add(term, scale)
          end

        Time ->
          fn %Time{} = term, {unit, scale} ->
            Time.add(term, scale, unit)
          end
      end

    limit_fun
    |> build_limits(term, opts)
    |> zip_limits(opts)
  end

  defp zip_limits({%mod{}, %mod{}} = limits, opts) do
    limits
    |> Tuple.to_list()
    |> Stream.map(&Map.take(&1, keys(mod)))
    |> Stream.zip_with(fn
      [{field, {lower, _}}, {field, {upper, _}}] ->
        {field, Range.new(lower, upper)}

      [{field, lower}, {field, upper}] ->
        {field, Range.new(lower, upper)}
    end)
    |> Enum.reject(fn {key, _limit} -> drop_opt?(key, opts[:scale]) end)
  end

  defp keys(DateTime), do: keys(Date) ++ keys(Time)
  defp keys(Date), do: [:year, :month, :day]
  defp keys(Time), do: [:hour, :minute, :second, :microsecond]

  defp drop_opt?(key, {unit, _}), do: less_precise?(key, unit)
  defp drop_opt?(_unit, _scale_opt), do: false

  defp less_precise?(key, key), do: false
  defp less_precise?(key, unit), do: datetime_index(key) > datetime_index(unit)

  defp datetime_index(key) do
    DateTime |> keys() |> Enum.find_index(&(&1 === key))
  end
end
