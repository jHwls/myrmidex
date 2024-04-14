defmodule Myrmidex.Helpers.Struct do
  @moduledoc false

  @doc false
  def implementer?(mod) do
    if function_exported?(mod, :__info__, 1) do
      :functions
      |> mod.__info__()
      |> then(&({:__struct__, 0} in &1))
    else
      false
    end
  end
end
