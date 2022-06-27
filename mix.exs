defmodule Web3.MixProject do
  use Mix.Project

  def project do
    [
      app: :web3,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ecto, "~> 3.7", optional: true},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_keccak, "~> 0.4.0"},
      {:httpoison, "~> 1.8", optional: true},
      {:mox, "~> 1.0", only: [:test]},
      {:ex_rlp, "~> 0.5.3"},
      {:curvy, "~> 0.3.0"}
    ]
  end
end
