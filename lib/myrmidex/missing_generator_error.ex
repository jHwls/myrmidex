defmodule Myrmidex.MissingGeneratorError do
  defexception [:message]

  @impl true
  def exception(e), do: %__MODULE__{message: msg(e)}

  defp msg(e) do
    "#{inspect(e.module)} does not define an implementation for #{mfa(e)} for arguments: #{inspect(e.args)}"
  end

  defp mfa(e), do: Exception.format_mfa(e.module, e.function, e.arity)
end
