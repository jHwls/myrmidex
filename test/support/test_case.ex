defmodule Myrmidex.Support.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using(_opts) do
    quote do
      use ExUnitProperties
      alias StreamData, as: SD
      import Myrmidex.Support.TestCase
    end
  end

  def generator_info(generator) do
    generator
    |> Function.info()
    |> Keyword.take([:name, :env])
    |> Keyword.values()
  end

  def stream_data?(term), do: is_struct(term, StreamData)

  def constant_generator?(%StreamData{generator: generator}, term) do
    [:"-constant/1-fun-0-", [^term]] = generator_info(generator)
  end

  def matching_generator?(term, term), do: true
  def matching_generator?(%mod{} = _generated, %mod{} = _term), do: true
  def matching_generator?(generated, term) when is_atom(generated) and is_atom(term), do: true
  def matching_generator?(generated, term) when is_map(generated) and is_map(term), do: true
  def matching_generator?(generated, term) when is_list(generated) and is_list(term), do: true
  def matching_generator?(generated, term) when is_tuple(generated) and is_tuple(term), do: true
  def matching_generator?(generated, term) when is_float(generated) and is_float(term), do: true
  def matching_generator?(generated, term) when is_pid(generated) and is_pid(term), do: true

  def matching_generator?(generated, term)
      when is_integer(generated) and is_integer(term),
      do: true

  def matching_generator?(generated, term)
      when is_bitstring(generated) and is_bitstring(term),
      do: true

  def matching_generator?(generated, term)
      when is_binary(generated) and is_binary(term),
      do: true

  def matching_generator?(generated, term)
      when is_reference(generated) and is_reference(term),
      do: true

  def matching_generator?(_generated_term, _term), do: false
end
