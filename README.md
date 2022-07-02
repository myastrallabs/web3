# Web3

[![Build Status](https://app.travis-ci.com/zven21/web3.svg?branch=main)](https://app.travis-ci.com/zven21/web3)

A Elixir library for interacting with Ethereum, inspired by [web3.py](https://github.com/ethereum/web3.py). It’s a high level, user-friendly Ethereum JSON-RPC Client.

## Example

```elixir
# Defining the application
defmodule MyApp.Application do
  use Web3, rpc_endpoint: "<PATH_TO_RPC_ENDPOINT>"

  # middleware (optional)
  # middleware MyApp.Middleware.Logger

  # dispatch (optional)
  dispatch :eth_getBalance, args: 2

  # contract (optinnal)
  contract :FirstContract, contract_address: "0xdAC17F958D2ee523a2206206994597C13D831ec7", abi_path: "path_to_abi.json"
end

# Get latest block number
iex> MyApp.Application.eth_blockNumber
{:ok, 15034908}

# Get address balance.
iex> MyApp.Application.eth_getBalance("0xF4986360a6d873ea02F79eC3913be6845e0308A4", "latest")
{:ok, 0}

# Get multi-addresses balance.
iex> MyApp.Application.eth_getBalance(["0xF4986360a6d873ea02F79eC3913be6845e0308A4", "0xF4986360a6d873ea02F79eC3913be6845e0308A4"], "latest")
{:ok,
  %{
    errors: [],
    params: ["0xF4986360a6d873ea02F79eC3913be6845e0308A4", "0xF4986360a6d873ea02F79eC3913be6845e0308A4"],
    result: [0, 0]
  }
}

# Query Contract
iex> MyApp.Application.FirstContract.balanceOf_address_("0xF4986360a6d873ea02F79eC3913be6845e0308A4")
{:ok, 0}

# Make Transaction
iex> MyApp.Application.FirstContract.approve_address_uint256_(
  "0x0000000000000000000000000000000000000000", 
  10, 
  gas_price: 12_000_000_000, 
  gas_limit: 300_000, 
  chain_id: 1, 
  nonce: 1,
  priv_key: "xxxxxxxxxxxxxxxxxxxxxxx"
)

{:ok, true}
```

## **Overview**

- [Getting started](guides/Getting%20Started.md)
- [ETH API](guides/ETH%20API.md)
- [SmartContract](guides/SmartContract.md)
- [Middleware](guides/Middleware.md)
- [Base API](guides/Base%20API.md)
- [Features](#Features)
- [Used in production?](#used-in-production)

## **Features**

- [x] Ethereum JSON-RPC Client
- [x] Interacting smart contracts
- [ ] Querying past events
- [ ] Event monitoring as Streams
- [ ] Websockets

## **Used in production?**

Web3 is under development and is not recommended for use in production environments

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
