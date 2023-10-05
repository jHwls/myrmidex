defmodule Myrmidex.OptsTest do
  use ExUnit.Case, async: true

  test "schema is valid" do
    %NimbleOptions{
      schema: [
        generator_schema: [
          required: false,
          type: :atom,
          default: Myrmidex.GeneratorSchemas.Default
        ],
        keys: [
          required: false,
          type: {:in, [:string, :atom]},
          default: :atom
        ],
        list_opts: [
          required: false,
          type: :keyword_list,
          default: [max_length: 30]
        ],
        drop_autogenerate?: [
          required: false,
          type: :boolean,
          default: false
        ],
        drop_associations?: [
          required: false,
          type: :boolean,
          default: false
        ]
      ]
    } = Myrmidex.Opts.schema()
  end
end
