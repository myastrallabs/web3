defmodule Web3.Dummy do
  @moduledoc false
  use Web3,
    id: :bsc_mainnet,
    chain_id: 56,
    json_rpc_arguments: [
      url: "https://bsc-dataseed4.ninicoin.io/",
      http: Web3.HTTP.HTTPoison,
      http_options: [
        recv_timeout: :timer.minutes(1),
        timeout: :timer.minutes(1),
        hackney: [pool: :web3]
      ]
    ]

  middleware(Web3.Middleware.CustomLogger)

  # dispatch(:eth_getBalance, args: 2, return_fn: :hex)
end
