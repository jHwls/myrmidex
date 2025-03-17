# Used by "mix format"
[
  import_deps: [:ecto, :stream_data],
  locals_without_parens: [one: 1, one: 2, many: 1, many: 2, fixture: 1],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [one: 1, one: 2, many: 1, many: 2, fixture: 1]
  ]
]
