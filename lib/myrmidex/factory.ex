defmodule Myrmidex.Factory do
  @moduledoc """
  Defines a behaviour and utility for associating GeneratorSchemas
  with a datasource. Typically used in your test support files as the
  definitive source for creating streams that make sense within
  your domain: i.e. your schemas.

  Opts based to this module via `use` are persisted at compile time
  and will be passed to, e.g. `&Myrmidex.stream/2`, in order to delegate
  to your domain-specific generator schema. This module itself uses
  `Myrmidex.GeneratorSchema`, so you may define all, or factory-specific,
  casts within the factory module, or fallback on any generator schema.

  Runtime opts passed in the second argument to `&to_stream/2` or
  `&attrs/2` will override these module-specific compile-time opts.

  Putting this all together, a basic implmentation could look something
  like:

  ```elixir
  # test/support/factory.ex

  defmodule MyApp.Support.Factory do
    use Myrmidex.Factory

    # Your factory api is up to you, but one option is to define streams
    # that can then be composed together before calling `&persist/3`.
    def my_schema_stream(overrides \\ [], stream_opts \\ []) do
      %MySchema{}
      |> Myrmidex.affix(overrides)
      |> to_stream(stream_opts)
    end

    @impl Myrmidex.Factory
    def insert(_module, [attrs]) do
      # Handle insert_one.
      # This is the place to invoke your changeset functions.
    end

    def insert(_module, attrs) when is_list(attrs) do
      # Handle insert_all.
    end

    @impl Myrmidex.GeneratorSchema
    def cast_field({_field, _type}, _opts) do
      # Handle and data-source specific casts: e.g. uuids, etc.
    end

    generator_schema_fallback(Myrmidex.GeneratorSchemas.Default)
  end
  ```
  Your setup functions might then look like:

  ```elixir
  # test/support/setup.ex

  alias MyApp.Support.Factory

  def seed_my_schema(context \\ %{}) do
    context
    |> # do anything with context
    |> Factory.my_schema_stream(overrides)
    |> Factory.persist()
  end
  ```

  Delaying the enumeration of streams leaves your factory functions
  very composable, and useful throughout your app, during testing and
  development.

  """

  @doc "Callback to insert one or many into a store"
  @callback insert(struct_mod :: module(), attrs :: term() | [term()]) :: any()
  @optional_callbacks [insert: 2]

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour Myrmidex.Factory
      use Myrmidex.GeneratorSchema
      alias StreamData, as: SD

      @opts opts
            |> Keyword.put_new(:generator_schema, __MODULE__)
            |> Keyword.put_new(:drop_autogenerate?, true)
            |> Keyword.put_new(:drop_associations?, true)
            |> Myrmidex.Opts.validate!()

      @doc """
      Runtime access to the validated Myrmidex.Factory opts for this 
      factory (#{inspect(__MODULE__)}).
            
      """
      def opts, do: @opts

      @moduledoc false
      defp __merge_opts__(opts) do
        Keyword.merge(@opts, opts)
      end

      @doc "See &Myrmidex.to_stream/2"
      def to_stream(term, opts \\ [])

      def to_stream(%SD{} = stream, _opts), do: stream

      def to_stream(term, opts) do
        opts
        |> __merge_opts__()
        |> then(&Myrmidex.to_stream(term, &1))
      end

      @doc "Build a stream and take one or many attrs"
      def attrs(term, count \\ 1, opts \\ []) do
        term
        |> to_stream(opts)
        |> Myrmidex.many(count)
      end

      @doc "Pass a stream to your datasource via the `&insert/1` callback"
      def persist(%SD{} = stream, struct_mod, count \\ 1) do
        stream
        |> Myrmidex.many(count)
        |> then(&Myrmidex.Factory.__insert__(__MODULE__, struct_mod, &1))
      end
    end
  end

  @doc false
  def __insert__(factory_mod, struct_mod, attrs) do
    apply(factory_mod, :insert, [struct_mod, attrs])
  rescue
    e in [UndefinedFunctionError] ->
      if e.module === factory_mod do
        reraise RuntimeError,
                "#{inspect(factory_mod)} does not define an implementation for &Myrmidex.Factory.insert/2",
                __STACKTRACE__
      else
        reraise e, __STACKTRACE__
      end
  end
end
