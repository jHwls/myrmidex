defmodule Myrmidex.Generators.Binary do
  @moduledoc false
  # String, Atom, and other binary generators.

  alias Myrmidex.Helpers
  alias StreamData, as: SD

  @doc false
  def uuid_stream_data do
    SD.repeatedly(&Ecto.UUID.autogenerate/0)
  end

  def uuid_stream_data(opts) do
    stream = uuid_stream_data()

    cond do
      Keyword.has_key?(opts, :prefix) ->
        Helpers.StreamData.bind_repeatedly!(stream, fn uuid -> opts[:prefix] <> uuid end)

      Keyword.has_key?(opts, :suffix) ->
        Helpers.StreamData.bind_repeatedly!(stream, fn uuid -> uuid <> opts[:suffix] end)

      true ->
        stream
    end
  end

  @doc false
  def string_stream_data(string) when is_binary(string) do
    cond do
      !String.printable?(string) ->
        SD.bitstring()

      Regex.match?(~r/^[[:alpha:]]*$/, string) ->
        SD.string([?a..?z, ?A..?Z])

      Regex.match?(~r/^[[:alnum:]]+$/, string) ->
        SD.string(:alphanumeric)

      true ->
        SD.string(:utf8)
    end
  end
end
