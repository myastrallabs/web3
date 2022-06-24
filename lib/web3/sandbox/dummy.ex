defmodule Web3.Dummy do
  @moduledoc false
  use Web3,
    name: :bsc_mainnet,
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
end
