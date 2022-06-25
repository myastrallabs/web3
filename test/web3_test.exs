defmodule Web3Test do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Web3

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  defmodule Dummy do
    use Web3,
      id: :bsc_mainnet,
      chain_id: 56,
      json_rpc_arguments: [
        url: "http://path_to_url.com",
        http: Web3.HTTP.Mox,
        http_options: [recv_timeout: 60_000, timeout: 60_000, hackney: [pool: :web3]]
      ]
  end

  test "eth_gasPrice/0" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(5_000_000_000)} |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    assert {:ok, 5_000_000_000} = Dummy.eth_gasPrice()
  end

  test "eth_getBalance/1" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    assert {:ok, 1} = Dummy.eth_getBalance("0x0000000000000000000000000000000000000000", "latest")
  end

  test "eth_blockNumber/0" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()
      {:ok, %{body: body, status_code: 200}}
    end)

    assert {:ok, 1} = Dummy.eth_blockNumber()
  end

  # describe "eth_getTransactionReceipt/1" do
  # test "with invalid transaction hash" do
  #   hash = "0x0000000000000000000000000000000000000000000000000000000000000000"

  #   expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
  #     {:ok, [%{id: 0, jsonrpc: "2.0", result: nil}]}
  #   end)

  #   assert {:ok, [%{id: 0, jsonrpc: "2.0", result: nil}]} = Dummy.eth_getTransactionReceipt(hash)
  # end

  # test "with valid transaction hash" do
  #   hash = "0xa2e81bb56b55ba3dab2daf76501b50dfaad240cccb905dbf89d65c7a84a4a48e"

  #   expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
  #     {:ok,
  #      [
  #        %{
  #          id: 0,
  #          jsonrpc: "2.0",
  #          result: %{
  #            "blockHash" => "0x29c850324e357f3c0c836d79860c5af55f7b651e5d7ee253c1af1b14908af49c",
  #            "blockNumber" => "0x414911",
  #            "contractAddress" => nil,
  #            "cumulativeGasUsed" => "0x5208",
  #            "gasUsed" => "0x5208",
  #            "logs" => [],
  #            "logsBloom" =>
  #              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  #            "root" => nil,
  #            "status" => "0x1",
  #            "transactionHash" => hash,
  #            "transactionIndex" => "0x0"
  #          }
  #        }
  #      ]}
  #   end)

  #   # assert {:ok, [_]} = Dummy.eth_getTransactionReceipt(hash)
  # end
  # end

  # test "eth_getBlockByHash/2" do
  #   assert true
  # end

  # test "eth_getBlockByNumber/2" do
  #   assert true
  # end

  # test "eth_getTransactionCount/2" do
  #   assert true
  # end

  # describe "eth_getLogs/1" do
  #   test "filter with address" do
  #     expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
  #       body = %{jsonrpc: "2.0", id: 1, result: []} |> Jason.encode!()
  #       {:ok, %{body: body, status_code: 200}}
  #     end)

  #     Web3.Dummy.eth_getLogs(%{address: ["0x0000000000000000000000000000000000000000"], fromBlock: Web3.to_hex(1), toBlock: Web3.to_hex(10)})
  #   end

  #   test "filter with topic" do
  #     assert true
  #   end
  # end
end
