defmodule Myrmidex.Support.DocsGeneratorSchema do
  @moduledoc false
  # A generator schema for making the docs cute.

  use Myrmidex.GeneratorSchema
  alias Myrmidex.Generators

  @impl Myrmidex.GeneratorSchema
  def cast(term, _opts) when is_binary(term) do
    if String.printable?(term) and String.length(term) === 1 do
      ascii_generator(term)
    else
      Generators.string(term)
    end
  end

  defp ascii_generator(string) do
    string
    |> String.to_charlist()
    |> List.first()
    |> ascii_range()
    |> StreamData.string(length: 1)
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

  generator_schema_fallback(Myrmidex.GeneratorSchemas.Default)
end
