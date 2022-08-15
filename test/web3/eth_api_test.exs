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

  describe "eth_sendRawTransaction/1" do
    test "multi request with after_dispatch" do
      expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
        body =
          [
            %{
              error: %{code: -32000, message: "INTERNAL_ERROR: nonce too low"},
              id: 0,
              jsonrpc: "2.0"
            },
            %{
              error: %{code: -32000, message: "INTERNAL_ERROR: nonce too low"},
              id: 1,
              jsonrpc: "2.0"
            },
            %{
              result: "0x0000000000000000000000000000000000000000000000000000000000000001",
              id: 2,
              jsonrpc: "2.0"
            }
          ]
          |> Jason.encode!()

        {:ok, %{body: body, status_code: 200}}
      end)

      assert {
               :ok,
               %{
                 errors: [%{error: %{code: -32000, message: "INTERNAL_ERROR: nonce too low"}, param: "0x2"}, %{error: %{code: -32000, message: "INTERNAL_ERROR: nonce too low"}, param: "0x1"}],
                 params: ["0x3"],
                 result: ["0x0000000000000000000000000000000000000000000000000000000000000001"]
               }
             } = ExampleApplication.eth_sendRawTransaction(["0x1", "0x2", "0x3"])
    end

    test "simple request with after_dispatch" do
      expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
        body =
          %{
            error: %{code: -32000, message: "INTERNAL_ERROR: nonce too low"},
            id: 1,
            jsonrpc: "2.0"
          }
          |> Jason.encode!()

        {:ok, %{body: body, status_code: 200}}
      end)

      assert {:error, %{code: -32000, message: "INTERNAL_ERROR: nonce too low"}} = ExampleApplication.eth_sendRawTransaction("0x1")
    end
  end
end
