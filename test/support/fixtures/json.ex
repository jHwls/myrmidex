defmodule Myrmidex.Support.Fixtures.JSON do
  @moduledoc false
  use Ecto.Schema

  def balance_transaction do
    %{
      "id" => "2b134329-a292-4643-b251-cf107083f6ec",
      "object" => "balance_transaction",
      "amount" => 29,
      "available_on" => "2015-01-18 22:40:28Z",
      "created" => "2037-10-08 16:49:27Z",
      "currency" => "usd"
    }
  end
end
