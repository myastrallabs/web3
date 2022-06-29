# Web3

[![Build Status](https://app.travis-ci.com/zven21/web3.svg?branch=main)](https://app.travis-ci.com/zven21/web3)

A Elixir library for interacting with Ethereum, inspired by [web3.py](https://github.com/ethereum/web3.py). It’s a high level, user-friendly Ethereum JSON-RPC Client.

## Example

```elixir
# Defining the application
defmodule MyApp.EthMainnet do
  use Web3, rpc_endpoint: "<PATH_TO_RPC_ENDPOINT>"

  # middleware (optional)
  middleware MyApp.Middleware.Logger

  # dispatch (optional)
  dispatch :eth_getBalance, args: 2

  # contract (optinnal)
  contract :FirstContract, contract_address: "0xdAC17F958D2ee523a2206206994597C13D831ec7", abi_path: "path_to_abi.json"
end

# (Optional) If you need to customise your middleware.
defmodule MyApp.Middleware.Logger do
  @moduledoc false

  @behaviour Web3.Middleware

  require Logger
  alias Web3.Middleware.Pipeline
  import Pipeline

  @doc "Before Request HTTP JSON RPC"
  def before_dispatch(%Pipeline{} = pipeline) do
    # Set metadata assigns here.
    Logger.info("MyApp before_dispatch")
    pipeline
  end

  @doc "After Request HTTP JSON RPC"
  def after_dispatch(%Pipeline{} = pipeline) do
    Logger.info("MyApp after_dispatch")
    pipeline
  end

  @doc "When after request HTTP JSON RPC failed"
  def after_failure(%Pipeline{} = pipeline) do
    Logger.info("MyApp after_failure")
    pipeline
  end
end

# Get latest block number
iex> MyApp.EthMainnet.eth_blockNumber
{:ok, 15034908}

# Get address balance.
iex> MyApp.EthMainnet.eth_getBalance("0xF4986360a6d873ea02F79eC3913be6845e0308A4", "latest")
{:ok, 0}

# Get multi-addresses balance.
iex> MyApp.EthMainnet.eth_getBalance(["0xF4986360a6d873ea02F79eC3913be6845e0308A4", "0xF4986360a6d873ea02F79eC3913be6845e0308A4"], "latest")
{:ok,
  %{
    errors: [],
    params_list: [
      {"0xF4986360a6d873ea02F79eC3913be6845e0308A4", 0},
      {"0xF4986360a6d873ea02F79eC3913be6845e0308A4", 0}
    ]
  }
}

# Query Contract
iex> MyApp.EthMainnet.FirstContract.balanceOf_address_("0xF4986360a6d873ea02F79eC3913be6845e0308A4")
{:ok, 0}

# Make Transaction
iex> MyApp.EthMainnet.FirstContract.approve_address_uint256_(
  "0x0000000000000000000000000000000000000000", 
  10, 
  gas_price: 12_000_000_000, 
  gas_limit: 300_000, 
  chain_id: 1, 
  nonce: 1
)

{:ok, true}
```

## **Overview**

- [Getting started](guides/Getting%20Started.md)
- [ETH API](guides/ETH%20API.md)
- [SmartContract](guides/SmartContract.md)
- [Middleware](guides/Middleware.md)
- [Variables](guides/Variables.md)
- [Base API](guides/Base%20API.md)
- [Examples](guides/Examples.md)
- [Features](#Features)
- [Used in production?](#used-in-production)

## **Used in production?**

Web3 is under development and is not recommended for use in production environments

## **Features**

- [x] Ethereum JSON-RPC Client
- [x] Interacting smart contracts
- [ ] Querying past events
- [ ] Event monitoring as Streams
- [ ] Websockets

## **Contributing**

Bug report or pull request are welcome.

## **Make a pull request**

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Please write unit test with your code if necessary.

## **License**

web3 is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
