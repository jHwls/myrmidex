defmodule Myrmidex do
  @moduledoc """
  A light wrapper around `StreamData`. Generate any data on the fly, or model
  the underlying types and common fields of domain-specific structs or schemas,
  optionally using custom generators. Aimed at speeding up test setup, and
  maximizing reusability of factory data throughout testing and development.

  Uses reflection and composition to provide sensible defaults and allow for
  maximum reusability in test setup, db or cache seeding, performance testing,
  or just general-purpose development utility.

  ## Quick example

  Generate representative data from any term:

      iex> "🐜"
      ...> |> Myrmidex.many()
      ...> |> Enum.join(" ")
      "🐩 🐰 🐡 🐂 🐏 🐁 🐋 🐤 🐪 🐭 🐏 🐨 🐋 🐁 🐚 🐤"

  Optionally, constrain or altogether prevent generation:

      iex> "🐜"
      ...> |> Myrmidex.fix()
      ...> |> Myrmidex.many()
      ...> |> Enum.join(" ")
      "🐜 🐜 🐜 🐜 🐜 🐜 🐜 🐜 🐜 🐜"

      iex> %{species: species_generator()}
      ...> |> Myrmidex.affix(kingdom: "Animalia", class: "Insecta")
      ...> |> Myrmidex.many()
      [
        %{
          kingdom: "Animalia",
          class: "Insecta",
          species: "🪰"
        },
        %{
          kingdom: "Animalia",
          class: "Insecta",
          species: "🐞"
        },
        ...
      ]

  ## More useful examples

  Say you're working with an api, and have defined the a schema for validation
  purposes:

  ```elixir
  defmodule MyApp.StripeApi.Responses.BalanceTransaction do
    use Ecto.Schema

    @primary_key {:id, :binary_id, autogenerate: true}
    embedded_schema do
      field :object, Ecto.Enum, values: [:balance_transaction]
      field :amount, :integer
      field :available_on, :utc_datetime
      field :created, :utc_datetime
      field :currency, :string
      ...
    end

  end
  ```

  Quickly develop in the REPL, or write tests against this schema using
  autogenerated stream data:

      iex> Mymidex.one(%BalanceTransaction{})
      %MyApp.StripeApi.Responses.BalanceTransaction{
        id: "2b134329-a292-4643-b251-cf107083f6ec",
        object: :balance_transaction,
        amount: 29,
        available_on: ~U[2015-01-18 22:40:28Z],
        created: ~U[2037-10-08 16:49:27Z],
        currency: "0RuOTBTOP4fYL"
      }

  The `currency` field string generation isn't particularly useful. Let's pin
  that value using `affix/2` and then generate a list of attrs with string keys
  we can use to test changeset functions:

      iex> %BalanceTransaction{}
      ...> |> Myrmidex.affix(currency: "usd")
      ...> |> Myrmidex.many(attr_keys: :string)
      [
        %{
          "id" => "7d8979b6-e99b-48d3-8acb-862866f6630a",
          "amount" => -51,
          "currency" => "usd",
          ...
        },
        %{
          "id" => "9be66e53-58e2-405a-9c7a-4ae6b536e3ce",
          "amount" => 37,
          "currency" => "usd",
          ...
        },
        ...
      ]

  Helpful, but we might want to customize the binary id generation, or handle
  other specifics of this api. We can do this with a `Myrmidex.GeneratorSchema`.

  Ideally, generator schemas are broad enough to cover segments of the schemas
  and/or structs in our application or domain, reducing the repetition of
  ad hoc test-data definitions throughout the codebase.

  If we're setting up tests or using this regularly, or we need generated fields
  to build upon or be constrained by one another (e.g. the two date fields in the
  example), we'd potentially want to go one step further and setup up a
  `Myrmidex.Factory`.

  Factories are also the place to define a relationship
  of a schema or set of schemas to a datastore.

  ## Options

  Factories and genrators accept the following common set of opts:

  #{NimbleOptions.docs(Myrmidex.Opts.schema())}

  """
  import Myrmidex.GeneratorSchema, only: [is_mappable: 1]
  alias Myrmidex.Helpers
  alias StreamData, as: SD

  @doc """
  The main entry point to working with stream data. Produces stream data from
  `term`, implementing inferred stream data types for fields.

  ### Examples

      iex> alias Myrmidex.Support.DocsGeneratorSchema
      iex> animojis = Myrmidex.to_stream("🐜", generator_schema: DocsGeneratorSchema)
      iex> animoji = Myrmidex.one(animojis)
      iex> [ascii_code] = String.to_charlist(animoji)
      iex> ascii_code in 128000..128048
      true

  """
  def to_stream(term, opts \\ []) do
    if Helpers.StreamData.stream_data?(term) do
      term
    else
      {generator_schema, opts} =
        opts
        |> Myrmidex.Opts.validate!()
        |> Keyword.pop!(:generator_schema)

      Myrmidex.GeneratorSchema.__cast__(generator_schema, term, opts)
    end
  end

  @doc """
  Build a stream of `term` and then emit a random representative.
  Generally useful with maps or structs, but can be used with any term.

  ### Examples

      iex> alias Myrmidex.Support.DocsGeneratorSchema
      iex> animoji = Myrmidex.one("🐜", generator_schema: DocsGeneratorSchema)
      iex> [ascii_code] = String.to_charlist(animoji)
      iex> ascii_code in 128000..128048
      true

  """
  def one(term, opts \\ [])

  def one(%Stream{} = stream, _opts) do
    take_one(stream)
  end

  def one(term, opts) do
    cond do
      Helpers.StreamData.stream_data?(term) ->
        term
        |> resize_stream()
        |> take_one()

      is_struct(term) ->
        term
        |> to_stream(opts)
        |> resize_stream()
        |> via!(&struct!(term.__struct__, &1))
        |> take_one()

      true ->
        term
        |> to_stream(opts)
        |> resize_stream()
        |> take_one()
    end
  end

  defp take_one(stream) do
    stream
    |> Enum.take(1)
    |> hd()
  end

  defp resize_stream(stream, multiplier \\ 1) do
    SD.resize(stream, Enum.random(1..(100 * multiplier)))
  end

  @doc """
  Build a stream of `term`, and then emit a list of size `count` of
  representative data. Like `many/2`, may also accept a range.

  Because of the call to `StreamData.resize/2`, this function prevents
  narrowing in favor of more randomly representative data.

  ### Examples

      iex> alias Myrmidex.Support.DocsGeneratorSchema
      iex> animoji = Myrmidex.many("🐜", 2..5, generator_schema: DocsGeneratorSchema)
      iex> ascii_codes = Enum.flat_map(animoji, & String.to_charlist(&1))
      iex> Enum.all?(ascii_codes, & &1 in 128000..128048)
      true

  """
  def many(term, count \\ nil, opts \\ [])

  def many(term, nil, opts) do
    opts = Myrmidex.Opts.validate!(opts)
    count = Keyword.get(opts, :default_many)
    many(term, count, opts)
  end

  def many(term, %Range{first: min, last: max}, opts) do
    many(term, Enum.random(min..max), opts)
  end

  def many(%Stream{} = stream, count, _opts) when is_integer(count) do
    Enum.take(stream, count)
  end

  def many(term, count, opts) when is_integer(count) do
    cond do
      Helpers.StreamData.stream_data?(term) ->
        term
        |> resize_stream(count)
        |> Enum.take(count)

      is_struct(term) ->
        term
        |> to_stream()
        |> resize_stream(count)
        |> via!(&struct!(term.__struct__, &1))
        |> Enum.take(count)

      true ->
        term
        |> to_stream(opts)
        |> resize_stream(count)
        |> Enum.take(count)
    end
  end

  @doc """
  Wrap any term except `%StreamData{}` in `StreamData.constant/1`.

  ### Examples

      iex> stream = Myrmidex.fix("🐜")
      iex> Myrmidex.many(stream, 3)
      ["🐜", "🐜", "🐜"]
      iex> match?(^stream, Myrmidex.fix(stream))
      true

  """
  def fix(term) do
    if Helpers.StreamData.stream_data?(term) do
      term
    else
      SD.constant(term)
    end
  end

  @doc """
  Given `term` and a compatible `term` of overrides, map values via
  `StreamData.constant/1` to override any derivation of values via
  reflection or pattern matching.

  Will not override previously defined generators.

  ### Examples

      iex> alias Myrmidex.Support.Fixtures.TestPumpkin
      iex> humfrey = Myrmidex.affix(%TestPumpkin{}, name: "Humfrey", eats: "🎃")
      iex> humfreys = Myrmidex.many(humfrey, 2)
      iex> match?([%TestPumpkin{name: "Humfrey", eats: "🎃"}, %TestPumpkin{name: "Humfrey"}], humfreys)
      true

  """
  def affix(%{} = term, overrides) when is_mappable(overrides) do
    overrides
    |> maybe_normalize_keys(key_type(term))
    |> Map.new(fn {field, value} -> {field, fix(value)} end)
    |> then(&Map.merge(term, &1))
  end

  defp maybe_normalize_keys(overrides, :mixed), do: overrides

  defp maybe_normalize_keys(overrides, key_type) do
    Stream.map(overrides, fn
      {field, value} when is_atom(field) and key_type === :atom ->
        {field, value}

      {field, value} when is_binary(field) and key_type === :string ->
        {field, value}

      {field, value} when is_binary(field) and key_type === :atom ->
        {String.to_existing_atom(field), value}

      {field, value} when is_atom(field) and key_type === :string ->
        {Atom.to_string(field), value}
    end)
  end

  defp key_type(term) do
    keys = Map.keys(term)

    cond do
      Enum.all?(keys, &is_atom/1) -> :atom
      Enum.all?(keys, &is_binary/1) -> :string
      true -> :mixed
    end
  end

  @doc """
  Same as `affix/2` but affixes a list of `term`.

  """
  def affix_many(%{} = term, count, overrides, opts \\ []) when is_mappable(overrides) do
    opts = Myrmidex.Opts.validate!(opts)
    count = count || Keyword.get(opts, :default_many)

    overrides
    |> Map.new(fn {field, value} ->
      stream =
        value
        |> fix()
        |> SD.list_of(length: count)

      {field, stream}
    end)
    |> then(&affix(term, &1))
  end

  @doc """
  Lazily transform the results of a stream via a function. I.e. just a
  shorthand for `StreamData.repeatedly/1` wrapped by `StreamData.bind/2`.

  """
  defdelegate via!(stream_data, via_fun), to: Helpers.StreamData, as: :bind_repeatedly!
end
