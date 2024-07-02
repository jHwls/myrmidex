defmodule Myrmidex.Setup do
  @moduledoc """
  Quickly scaffold setup modules with a common api.

  """
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Myrmidex.Setup, only: :macros
      @module_opts opts
    end
  end

  @schema NimbleOptions.new!(
            tag: [
              type: :atom,
              type_doc: false,
              required: true
            ],
            struct: [
              type: :atom,
              type_doc: false
            ],
            stream: [
              type: {:or, [:atom, {:tuple, [:atom, :atom]}]},
              type_doc: false
            ],
            stream_opts: [
              type: :keyword_list,
              default: []
            ],
            factory: [
              type: :atom,
              type_doc: false
            ],
            require: [
              type: {:list, :atom}
            ]
          )

  def __build_and_validate_opts__!(opts, tag, setup_mod) do
    opts =
      opts
      |> Keyword.put(:tag, tag)
      |> NimbleOptions.validate!(@schema)

    opts
    |> Keyword.put_new(:stream, {setup_mod, :"#{tag}_stream"})
    |> Keyword.put(:require, {setup_mod, opts[:require]})
  end

  def __build_and_validate_many_opts__!(opts, tag, setup_mod) do
    tag_singular =
      tag
      |> Atom.to_string()
      |> String.replace_trailing("s", "")

    opts
    |> Keyword.put_new(:stream, {setup_mod, :"#{tag_singular}_stream"})
    |> __build_and_validate_opts__!(tag, setup_mod)
  end

  defmacro one(tag, opts \\ []) do
    quote bind_quoted: [tag: tag, opts: opts] do
      @opts @module_opts
            |> Keyword.merge(opts)
            |> Myrmidex.Setup.__build_and_validate_opts__!(tag, __MODULE__)

      @doc "Generate attributes for #{tag}."
      def unquote(:"#{tag}_attrs")(context_or_overrides \\ [], stream_opts \\ []) do
        Myrmidex.Setup.one_attrs(
          unquote(tag),
          unquote(@opts[:stream]),
          context_or_overrides,
          unquote(@opts[:require]),
          Keyword.merge(@opts[:stream_opts], stream_opts)
        )
      end

      @doc "Build one #{tag}, bypassing the datastore."
      def unquote(:"#{tag}")(context_or_overrides \\ [], stream_opts \\ []) do
        Myrmidex.Setup.one(
          unquote(tag),
          unquote(@opts[:stream]),
          unquote(@opts[:struct]),
          context_or_overrides,
          unquote(@opts[:require]),
          Keyword.merge(@opts[:stream_opts], stream_opts)
        )
      end

      # TODO: "needs to be a schema with source"
      @doc "Persist one #{tag} in the associated datastore."
      def unquote(:"seed_#{tag}")(context_or_overrides \\ [], stream_opts \\ []) do
        Myrmidex.Setup.seed_one(
          unquote(tag),
          unquote(@opts[:stream]),
          unquote(@opts[:struct]),
          unquote(@opts[:factory]),
          context_or_overrides,
          unquote(@opts[:require]),
          Keyword.merge(@opts[:stream_opts], stream_opts)
        )
      end
    end
  end

  defmacro many(tag, opts \\ []) do
    quote bind_quoted: [tag: tag, opts: opts] do
      @opts @module_opts
            |> Keyword.merge(opts)
            |> Myrmidex.Setup.__build_and_validate_many_opts__!(tag, __MODULE__)

      @doc "Generate many attributes for #{tag}."
      def unquote(:"#{tag}_attrs")(context_or_overrides \\ [], count \\ nil, stream_opts \\ []) do
        Myrmidex.Setup.many_attrs(
          unquote(tag),
          count,
          unquote(@opts[:stream]),
          context_or_overrides,
          unquote(@opts[:require]),
          Keyword.merge(@opts[:stream_opts], stream_opts)
        )
      end

      @doc "Build many #{tag}, bypassing the datastore."
      def unquote(:"#{tag}")(context_or_overrides \\ [], count \\ nil, stream_opts \\ []) do
        Myrmidex.Setup.many(
          unquote(tag),
          count,
          unquote(@opts[:stream]),
          unquote(@opts[:struct]),
          context_or_overrides,
          unquote(@opts[:require]),
          Keyword.merge(@opts[:stream_opts], stream_opts)
        )
      end

      @doc "Persist many #{tag} in the associated datastore."
      def unquote(:"seed_#{tag}")(context_or_overrides \\ [], count \\ nil, stream_opts \\ []) do
        Myrmidex.Setup.seed_many(
          unquote(tag),
          count,
          unquote(@opts[:stream]),
          unquote(@opts[:struct]),
          unquote(@opts[:factory]),
          context_or_overrides,
          unquote(@opts[:require]),
          Keyword.merge(@opts[:stream_opts], stream_opts)
        )
      end
    end
  end

  defmacro fixture(opts \\ []) do
    {one_tag, opts} = Keyword.pop!(opts, :one)
    {many_tag, opts} = Keyword.pop!(opts, :many)

    quote bind_quoted: [one_tag: one_tag, many_tag: many_tag, opts: opts] do
      Myrmidex.Setup.one(one_tag, opts)
      Myrmidex.Setup.many(many_tag, opts)
    end
  end

  defp build_stream(
         tag,
         {mod, fun} = _stream,
         %{} = context,
         require,
         stream_opts,
         via_fun \\ nil
       ) do
    overrides = Map.get(context, :"#{tag}_overrides", [])

    cond do
      Keyword.keyword?(overrides) or is_map(overrides) ->
        overrides = build_overrides(overrides, context, require)

        stream =
          mod
          |> apply(fun, [overrides, stream_opts])
          |> via!(via_fun)

        {stream, nil}

      is_list(overrides) ->
        stream =
          overrides
          |> Stream.map(&build_overrides(&1, context, require))
          |> Stream.map(fn overrides ->
            mod
            |> apply(fun, [overrides, stream_opts])
            |> via!(via_fun)
            |> Myrmidex.one()
          end)

        {stream, length(overrides)}
    end
  end

  defp build_overrides(overrides, %{} = _context, {_setup_mod, nil}), do: overrides

  defp build_overrides(overrides, %{} = context, {setup_mod, require_funs}) do
    Enum.reduce(require_funs, overrides, fn require_fun, acc ->
      apply(setup_mod, require_fun, [acc, context])
    end)
  end

  defp via!(stream, nil), do: stream

  defp via!(stream, via_fun) do
    Myrmidex.via!(stream, via_fun)
  end

  @doc "Generates, by default, string-keyed attrs for testing changesets."
  def one_attrs(tag, stream, %{test_type: :test} = context, require, stream_opts) do
    {stream, _limit} = attrs_stream(tag, stream, context, require, stream_opts)
    %{:"#{tag}_attrs" => Myrmidex.one(stream)}
  end

  def one_attrs(tag, stream, overrides, require, stream_opts)
      when is_list(overrides)
      when is_map(overrides) do
    context = %{:"#{tag}_overrides" => overrides}
    {stream, _limit} = attrs_stream(tag, stream, context, require, stream_opts)
    Myrmidex.one(stream)
  end

  @doc "Generates, by default, many string-keyed attrs."
  def many_attrs(tag, count, stream, %{test_type: :test} = context, require, stream_opts) do
    {stream, limit} = attrs_stream(tag, stream, context, require, stream_opts)
    attrs_list = Myrmidex.many(stream, limit || count)
    %{:"#{tag}_attrs" => attrs_list}
  end

  def many_attrs(tag, count, stream, overrides, require, stream_opts)
      when is_list(overrides)
      when is_map(overrides) do
    context = %{:"#{tag}_overrides" => overrides}
    {stream, limit} = attrs_stream(tag, stream, context, require, stream_opts)
    Myrmidex.many(stream, limit || count)
  end

  defp attrs_stream(tag, stream, context, require, stream_opts) do
    stream_opts =
      stream_opts
      |> Keyword.put_new(:drop_autogenerate?, true)
      |> Keyword.put_new(:attr_keys, :string)

    via_fun = &Map.reject(&1, fn {_k, v} -> is_nil(v) end)
    build_stream(tag, stream, context, require, stream_opts, via_fun)
  end

  @doc "Generates a representative of a map or struct."
  def one(tag, stream, struct, %{test_type: :test} = context, require, stream_opts) do
    {stream, _limit} = one_stream(tag, stream, struct, context, require, stream_opts)
    %{:"#{tag}" => Myrmidex.one(stream)}
  end

  def one(tag, stream, struct, overrides, require, stream_opts) do
    context = %{:"#{tag}_overrides" => overrides}
    {stream, _limit} = one_stream(tag, stream, struct, context, require, stream_opts)
    Myrmidex.one(stream)
  end

  @doc "Generates many representatives of a map or struct."
  def many(
        tag,
        count,
        stream,
        struct,
        %{test_type: :test} = context,
        require,
        stream_opts
      ) do
    {stream, limit} = one_stream(tag, stream, struct, context, require, stream_opts)
    many = Myrmidex.many(stream, limit || count)
    %{:"#{tag}" => many}
  end

  def many(tag, count, stream, struct, overrides, require, stream_opts) do
    context = %{:"#{tag}_overrides" => overrides}
    {stream, limit} = one_stream(tag, stream, struct, context, require, stream_opts)
    Myrmidex.many(stream, limit || count)
  end

  defp one_stream(tag, stream, nil, context, require, stream_opts) do
    stream_opts = Keyword.put_new(stream_opts, :drop_autogenerate?, true)
    build_stream(tag, stream, context, require, stream_opts)
  end

  defp one_stream(tag, stream, struct, context, require, stream_opts)
       when is_atom(struct) do
    stream_opts = Keyword.put_new(stream_opts, :drop_autogenerate?, true)
    via_fun = &struct(struct, &1)
    build_stream(tag, stream, context, require, stream_opts, via_fun)
  end

  @doc "Persists a struct via `c:Myrmidex.Factory.persist/3`."
  def seed_one(tag, stream, struct, factory, %{test_type: :test} = context, require, stream_opts) do
    {stream, _limit} = build_stream(tag, stream, context, require, stream_opts)
    {:ok, one} = apply(factory, :persist, [stream, struct, 1, stream_opts])
    %{:"#{tag}" => one}
  end

  def seed_one(tag, stream, struct, factory, overrides, require, stream_opts) do
    context = %{:"#{tag}_overrides" => overrides}
    {stream, _limit} = build_stream(tag, stream, context, require, stream_opts)
    apply(factory, :persist, [stream, struct, 1, stream_opts])
  end

  @doc "Persists many structs via `c:Myrmidex.Factory.persist/3`."
  def seed_many(
        tag,
        count,
        stream,
        struct,
        factory,
        %{test_type: :test} = context,
        require,
        stream_opts
      ) do
    {stream, limit} = build_stream(tag, stream, context, require, stream_opts)
    {:ok, many} = apply(factory, :persist, [stream, struct, limit || count, stream_opts])
    %{:"#{tag}" => many}
  end

  def seed_many(tag, count, stream, struct, factory, overrides, require, stream_opts) do
    context = %{:"#{tag}_overrides" => overrides}
    {stream, limit} = build_stream(tag, stream, context, require, stream_opts)
    apply(factory, :persist, [stream, struct, limit || count, stream_opts])
  end
end
