defmodule Myrmidex.OptsTest do
  use ExUnit.Case, async: true

  test "schema is valid" do
    assert %NimbleOptions{
             schema: [
               generator_schema: [
                 required: false,
                 type: :atom,
                 type_doc: false,
                 default: Myrmidex.GeneratorSchemas.Default
               ],
               limit_generation?: [
                 required: false,
                 type: :boolean,
                 default: false,
                 doc: _
               ],
               attr_keys: [
                 required: false,
                 type: {:in, [:string, :atom]},
                 type_doc: "`:string` or `:atom`",
                 doc: _
               ],
               drop_autogenerate?: [
                 required: false,
                 type: :boolean,
                 default: false,
                 doc: _
               ],
               drop_associations?: [
                 required: false,
                 type: :boolean,
                 default: false,
                 doc: _
               ],
               list_opts: [
                 required: false,
                 type: :keyword_list,
                 default: [max_length: 30],
                 doc: _
               ]
             ]
           } = Myrmidex.Opts.schema()
  end
end
