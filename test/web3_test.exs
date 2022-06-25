defmodule Web3Test do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Web3

  import Mox

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

  describe "Web3.Eth.API" do
    test "eth_getBalance/2" do
      Web3.HTTP.Mox
      |> expect(:json_rpc, fn _url, _json, _options ->
        body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()

        {:ok, %{body: body, status_code: 200}}
      end)

      assert {:ok, 1} = Dummy.eth_getBalance("0x0000000000000000000000000000000000000000", "latest")
    end

    test "eth_blockNumber/2" do
      Web3.HTTP.Mox
      |> expect(:json_rpc, fn _url, _json, _options ->
        body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()

        {:ok, %{body: body, status_code: 200}}
      end)

      assert {:ok, 1} = Dummy.eth_blockNumber()
    end
  end
end
