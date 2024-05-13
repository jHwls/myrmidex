defmodule Myrmidex.ReadmeTest do
  use ExUnit.Case, async: true

  # https://twitter.com/royalicing/status/1687271985548820480
  test "readme version and mix.exs version match" do
    readme_md = File.read!(Path.join(__DIR__, "../README.md"))
    version = Keyword.get(Mix.Project.config(), :version)
    assert version === "0.3.0"
    assert readme_md =~ ~s({:myrmidex, "~> #{version}", only: [:test, :dev]})
  end
end
