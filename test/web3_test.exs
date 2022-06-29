defmodule Web3Test do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Web3

  defmodule FirstApplication do
    use Web3, rpc_endpoint: "http://localhost:8545", http: Web3.HTTP.Mox
  end

  defmodule SecondApplication do
    use Web3, rpc_endpoint: "http://localhost:8545", http: Web3.HTTP.Mox

    dispatch :eth_getBalance, args: 2, name: :eth_getBalance_2

    middleware Web3.Middleware.Logger

    contract :FirstContract, contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", abi_path: Path.join([__DIR__, "./support/fixtures/BUSD.abi.json"])
  end

  describe "application config()" do
    test "get application default config/0" do
      assert [
               middleware: [Web3.Middleware.Parser, Web3.Middleware.RequestInspector, Web3.Middleware.ResponseFormatter],
               http_options: [recv_timeout: 60000, timeout: 60000, hackney: [pool: :web3]],
               rpc_endpoint: "http://localhost:8545",
               http: Web3.HTTP.Mox
             ] = FirstApplication.config()
    end
  end

  describe "application contracts" do
    test "get application custom middleware" do
      assert [
               FirstContract: [
                 contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
                 abi_path: "/Users/zven/damo/web3/test/./support/fixtures/BUSD.abi.json"
               ]
             ] = SecondApplication.contracts()
    end
  end

  describe "application methods" do
    test "get application default method" do
      assert [
               eth_blockNumber: [return_fn: :int],
               eth_getBalance: [args: 2, return_fn: :int],
               eth_gasPrice: [return_fn: :int],
               eth_getTransactionReceipt: [args: 1],
               eth_getBlockByHash: [args: 2],
               eth_getBlockByNumber: [args: 2],
               eth_getTransactionCount: [args: 2, return_fn: :int],
               eth_getLogs: [args: 1],
               eth_sendRawTransaction: [args: 1],
               eth_getCode: [args: 2],
               net_version: [return_fn: :integer],
               eth_getTransactionByHash: [args: 1],
               eth_getUncleByBlockHashAndIndex: [args: 2],
               eth_getTransactionByBlockHashAndIndex: [args: 2],
               eth_getTransactionByBlockNumberAndIndex: [args: 2],
               eth_getBlockTransactionCountByHash: [args: 1],
               eth_getBlockTransactionCountByNumber: [args: 1]
             ] = FirstApplication.methods()
    end

    test "get default with custom method" do
      assert [
               eth_blockNumber: [return_fn: :int],
               eth_getBalance: [args: 2, return_fn: :int],
               eth_gasPrice: [return_fn: :int],
               eth_getTransactionReceipt: [args: 1],
               eth_getBlockByHash: [args: 2],
               eth_getBlockByNumber: [args: 2],
               eth_getTransactionCount: [args: 2, return_fn: :int],
               eth_getLogs: [args: 1],
               eth_sendRawTransaction: [args: 1],
               eth_getCode: [args: 2],
               net_version: [return_fn: :integer],
               eth_getTransactionByHash: [args: 1],
               eth_getUncleByBlockHashAndIndex: [args: 2],
               eth_getTransactionByBlockHashAndIndex: [args: 2],
               eth_getTransactionByBlockNumberAndIndex: [args: 2],
               eth_getBlockTransactionCountByHash: [args: 1],
               eth_getBlockTransactionCountByNumber: [args: 1],
               eth_getBalance: [name: :eth_getBalance_2, args: 2]
             ] = SecondApplication.methods()
    end
  end

  describe "middleware/0" do
    test "get application default middleware" do
      assert [
               Web3.Middleware.Parser,
               Web3.Middleware.RequestInspector,
               Web3.Middleware.ResponseFormatter
             ] = FirstApplication.middleware()
    end
  end
end
