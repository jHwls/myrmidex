defmodule Myrmidex.Support.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using(_opts) do
    quote do
      use ExUnitProperties
      alias StreamData, as: SD
    end
  end
end
