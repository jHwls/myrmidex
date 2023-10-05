defmodule Myrmidex.Opts do
  @moduledoc false

  @schema NimbleOptions.new!(
            generator_schema: [
              type: :atom,
              default: Myrmidex.GeneratorSchemas.Default
            ],
            keys: [
              type: {:in, [:string, :atom]},
              default: :atom
            ],
            list_opts: [
              type: :keyword_list,
              default: [max_length: 30]
            ],
            drop_autogenerate?: [
              type: :boolean,
              default: false
            ],
            drop_associations?: [
              type: :boolean,
              default: false
            ]
          )

  @doc false
  def schema, do: @schema

  @doc false
  def validate!(opts) do
    NimbleOptions.validate!(opts, @schema)
  end
end
