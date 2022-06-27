defmodule Web3.Config do
  @moduledoc """
  Web3 Config

  ## Examples

    config :web3, FirstApp,
      rpc_endpoint: "http://localhost:8545",
      http: Web3.HTTP.HTTPoison,
      http_options: [recv_timeout: 60_000, timeout: 60_000, hackney: [pool: :web3]]

    config :web3, SecondApp,
      rpc_endpoint: "http://localhost:8545",
      http: Web3.HTTP.HTTPoison,
      http_options: [recv_timeout: 60_000, timeout: 60_000, hackney: [pool: :web3]]

    config :web3, FirstApp.FirstContract,
      contract_address: "",
      priv_key: "",
      chain_id: "",
      gas_limit: "",
      gas_price: ""

  """

  @doc false
  def compile_config(module_name, default_config, opts) do
    config = Application.get_env(:web3, module_name, [])

    default_config
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
  end
end
