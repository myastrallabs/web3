defmodule Web3.MixProject do
  use Mix.Project

  @version "0.1.4"
  @github "https://github.com/zven21/web3"

  def project do
    [
      app: :web3,
      version: @version,
      description: "A Elixir library for interacting with Ethereum",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "web3",
      source_url: @github
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Web3.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3"},
      {:ecto, "~> 3.7"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_keccak, "~> 0.4.0"},
      {:ex_rlp, "~> 0.5.3"},
      {:curvy, "~> 0.3.0"},
      {:httpoison, "~> 1.8"},
      {:nimble_parsec, "~> 1.2.3"},
      {:mox, "~> 1.0", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "web3",
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE* license* CHANGELOG* changelog* guides),
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      maintainers: ["zven21"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @github,
      formatters: ["html"]
    ]
  end
end
