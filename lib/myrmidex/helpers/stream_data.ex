defmodule Myrmidex.Helpers.StreamData do
  @moduledoc false

  @doc false
  def stream_data?(%StreamData{}), do: true
  def stream_data?(_term), do: false

  @doc false
  def bind_repeatedly!(stream_data, fun) when is_function(fun, 1) do
    if stream_data?(stream_data) do
      bind_repeatedly_fun(stream_data, fun)
    else
      raise ArgumentError,
        message: "first argument must be stream data; received `#{inspect(stream_data)}`"
    end
  end

  defp bind_repeatedly_fun(stream_data, fun) do
    StreamData.bind(stream_data, fn term ->
      StreamData.repeatedly(fn -> fun.(term) end)
    end)
  end
end
