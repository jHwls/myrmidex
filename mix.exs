defmodule Myrmidex.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/jhwls/myrmidex"

  def project do
    [
      app: :myrmidex,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      # Hex
      description:
        "Power testing & development with multitudes via streams and the StreamData lib 🐜🐜🐜🐜🐜🐜🐜",
      package: [
        maintainers: ["J Howells"],
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @repo_url}
      ],
      # Coverage
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      # Dialyzer
      dialyzer: [
        plt_add_deps: :app_tree,
        plt_local_path: ".dialyzer/local_plt",
        plt_core_path: ".dialyzer/core_plt",
        ignore_warnings: ".dialyzer/dialyzer-ignore.exs",
        list_unused_filters: true,
        flags: [
          :no_opaque
        ]
      ]
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, ">= 3.0.0"},
      {:nimble_options, ">= 0.5.0"},
      {:stream_data, ">= 0.6.0"},
      ###
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:excoveralls, "~> 0.17", only: [:test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "Myrmidex",
      source_url: @repo_url,
      extras: ["README.md": [title: "README"], "LICENSE.md": []],
      groups_for_modules: [
        "Generator Schemas": [
          Myrmidex.GeneratorSchema,
          Myrmidex.GeneratorSchemas.Default
        ],
        Factories: [
          Myrmidex.Factory
        ],
        Helpers: [
          Myrmidex.Helpers.StreamData
        ]
      ]
    ]
  end
end
