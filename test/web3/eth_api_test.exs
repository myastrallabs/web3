defmodule Web3.EthAPITest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Web3

  import Mox

  setup :verify_on_exit!

  defmodule ExampleApplication do
    use Web3, rpc_endpoint: "http://localhost:8545", http: Web3.HTTP.Mox
  end

  test "eth_blockNumber/0" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()
      {:ok, %{body: body, status_code: 200}}
    end)

    assert {:ok, 1} = ExampleApplication.eth_blockNumber()
  end

  test "eth_gasPrice/0" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(5_000_000_000)} |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    assert {:ok, 5_000_000_000} = ExampleApplication.eth_gasPrice()
  end

  test "eth_getBalance/1" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    assert {:ok, 1} = ExampleApplication.eth_getBalance("0x0000000000000000000000000000000000000000", "latest")
  end
end
