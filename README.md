# Myrmidex

![ci](https://github.com/jhwls/myrmidex/actions/workflows/ci.yml/badge.svg?event=push)
[![Hex.pm](https://img.shields.io/hexpm/v/myrmidex.svg)](https://hex.pm/packages/myrmidex)
[![Documentation](https://img.shields.io/badge/docs-grey)](https://hexdocs.pm/myrmidex)
[![coverage](https://codecov.io/gh/jHwls/myrmidex/graph/badge.svg?token=LKU73RD6E6)](https://codecov.io/gh/jHwls/myrmidex)

A light wrapper around `StreamData`. Generate any data on the fly, or model
the underlying types and common fields of domain-specific structs or schemas,
optionally using custom generators. Aimed at speeding up test setup, and
maximizing reusability of factory data throughout testing and development.

## Installation

Add to your list of test dependencies in `mix.exs`, optionally also including
in `dev` if you want to be able to use in IEx:

```elixir
def deps do
  [
    {:myrmidex, "~> 0.2.0", only: [:test, :dev]}
  ]
end
```

## Usage

Produce a stream of generically representative data from any term:

```elixir
iex> "🐜"
...> |> Myrmidex.many()
...> |> Enum.join(" ")
"🐩 🐰 🐡 🐂 🐏 🐁 🐋 🐤 🐪 🐭 🐏 🐨 🐋 🐁 🐚 🐤"

iex> %{species: "🐜"}
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

```

See the [main module](https://hexdocs.pm/myrmidex/Myrmidex.html) (`h Myrmidex`) for examples of mocking
structs and schemas, defining custom generator schemas, or hooking
generation to persistance via factories.

## Design goals

- Initial, usable defaults, which can be extended with domain-specific
  concerns
- Decouple any requirements wrt to seeding a datasource from the generation
  of data
- Avoid unnecessary dependencies and testing setup
- Avoid any kind of dsl (besides that introduced by StreamData in
  `ExUnitProperties`, which is useful for property-based testing)
- Rely on reflection and introspection as much as possible to avoid boilerplate
  and repetition, and also to keep factories in sync with schemas
- Establish a robust, composable api from which to generate mock data
  in many situations: test setup, dev setup, prototyping, etc., testing
  changesets and validation vs testing context functions, and so on.
- Reduce the complexity (and conversely, increase the flexibilty &
  reusability) involved in mocking schemas with associations, or other
  interdependencies between fields
- Retain compatibilty with StreamData and property testing

## Roadmap

- ~~Better generation of vanilla maps and lists~~
- Reporting on generated terms
- Better defaults for strings/emails etc.
- Option to control shrinking
- Option to control the default count
- Inference/generation of ISO dates and datetimes
- Better integration with vanilla streams
