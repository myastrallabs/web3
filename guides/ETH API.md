## ETH API

### Built-in Methods

Web3 has the following methods built in: 

- eth_blockNumber/0
- eth_getBalance/2
- eth_getBlockByHash/2
- eth_getBlockByNumber/2
- eth_getCode/2
- net_version/0
- eth_getTransactionByHash/1
- eth_getUncleByBlockHashAndIndex/2
- eth_getTransactionByBlockHashAndIndex/2
- eth_getTransactionByBlockNumberAndIndex/2
- eth_getBlockTransactionCountByHash/1
- eth_getBlockTransactionCountByNumber/1
- eth_getTransactionReceipt/1
- eth_gasPrice/0
- eth_getTransactionCount/2
- eth_sendRawTransaction/1

You can get details at [Infura.io](https://docs.infura.io/infura/networks/ethereum/json-rpc-methods/eth_gasprice)

### Customised Method

By the way, you can define the eth API.

```elixir
defmodule MyApp.MyApplication do
  use Web3, rpc_endpoint: "https://bsc-dataseed4.ninicoin.io"

  dispatch :eth_chainId, args: 0
end
```

Macro dispatch receives 2 parameters.

- Infura same method name, e.g.: :eth_chainId
- Options:

  Field       | Required|  Description          | Default
  ----------- | --------| --------- | -------------
  `name`      | `false`  | Alias name | (empty)
  `args`      | `false`  | Number of parameters received by the method |  0
  `return_fn` | `false`  | Return value types, you can use anonymous functions | :raw
  
  
### Configuration

Two ways to define variables

```elixir
defmodule MyApp.MyApplication do
  use Web3, rpc_endpoint: "<PATH>"
end
```
Or:

```elixir
config :web3, 
  rpc_endpoint: "<PATH>"
```
#### Variable:

  Field       | Required|  Description          | Default
  ----------- | --------| --------------------- | -------------
  `rpc_endpoint`      | `true`  | RPC Endpoint URL | 
  `http`      | `false`  | HTTP Request |  `Web3.HTTP.HTTPoison`
  `http_options` | `false`  | HTTP Request Options | `[recv_timeout: 60_000, timeout: 60_000]`
  `priv_key` | `false`  | Private key, if you want to send a transaction | 
  `chain_id` | `false`  | Chain Id, visit [chainlist](https://chainlist.org/) | 
  `gas_limit` | `false`  | Gas Limit | 
  `gas_price` | `false`  | Gas Price | 
