defmodule Myrmidex.MissingGeneratorError do
  defexception [:message]

  @impl true
  def exception({generator_schema, field_type_tuple}) do
    msg =
      "#{inspect(generator_schema)} does not define an implementation for &Myrmidex.GeneratorSchema.cast_field/2 for: #{inspect(field_type_tuple)}"

    %__MODULE__{message: msg}
  end
end
