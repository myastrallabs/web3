defmodule Web3.ContractTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Web3.ABI

  import Mox

  setup :verify_on_exit!

  defmodule FirstApplication do
    use Web3, rpc_endpoint: "http://localhost:8545", http: Web3.HTTP.Mox
  end

  @erc20_abi [
    %{
      inputs: [%{internalType: "address", name: "owner", type: "address"}],
      name: "balanceOf",
      outputs: [%{internalType: "uint256", name: "", type: "uint256"}],
      stateMutability: "view",
      type: "function"
    },
    %{
      constant: false,
      inputs: [
        %{internalType: "address", name: "spender", type: "address"},
        %{internalType: "uint256", name: "amount", type: "uint256"}
      ],
      name: "approve",
      outputs: [%{internalType: "bool", name: "", type: "bool"}],
      payable: false,
      stateMutability: "nonpayable",
      type: "function"
    },
    %{
      constant: true,
      inputs: [],
      name: "name",
      outputs: [%{internalType: "string", name: "", type: "string"}],
      payable: false,
      stateMutability: "view",
      type: "function"
    }
  ]

  describe "ERC20 Contract" do
    test "request with empty args" do
      expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
        body =
          %{
            id: 0,
            jsonrpc: "2.0",
            result:
              "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a4255534420546f6b656e00000000000000000000000000000000000000000000"
          }
          |> Jason.encode!()

        {:ok, %{body: body, status_code: 200}}
      end)

      request = %{contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", method_name: :name}
      assert [ok: "BUSD Token"] = FirstApplication.execute_contract(request, @erc20_abi)
    end

    test "request method_name eq :name" do
      expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
        body =
          %{
            id: 0,
            jsonrpc: "2.0",
            result:
              "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a4255534420546f6b656e00000000000000000000000000000000000000000000"
          }
          |> Jason.encode!()

        {:ok, %{body: body, status_code: 200}}
      end)

      requests = [
        %{
          args: [],
          method_name: :name,
          contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56"
        }
      ]

      assert [ok: "BUSD Token"] = FirstApplication.execute_contract(requests, @erc20_abi)
    end
  end

  test "request method_name eq :balanceOf" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body =
        %{
          id: 0,
          jsonrpc: "2.0",
          result: "0x0000000000000000000000000000000000000000000000a3307e346e3edab2c1"
        }
        |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    requests = [
      %{
        args: ["0x0000000000000000000000000000000000000000"],
        method_name: :balanceOf,
        contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56"
      }
    ]

    assert [ok: 3_010_313_572_023_648_563_905] = FirstApplication.execute_contract(requests, @erc20_abi)
  end

  test "request not exist method" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body =
        %{
          id: 0,
          jsonrpc: "2.0",
          error: %{code: -32000, message: "execution reverted"}
        }
        |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    requests = [
      %{
        args: ["0x0000000000000000000000000000000000000000"],
        method_name: :balanceOf,
        contract_address: "0x0000000000000000000000000000000000000000"
      }
    ]

    assert [error: %{code: -32000, message: "execution reverted"}] = FirstApplication.execute_contract(requests, @erc20_abi)
  end

  test "multi requests" do
    expect(Web3.HTTP.Mox, :json_rpc, fn _url, _json, _options ->
      body =
        [
          %{
            id: 0,
            jsonrpc: "2.0",
            result:
              "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a4255534420546f6b656e00000000000000000000000000000000000000000000"
          },
          %{
            id: 1,
            jsonrpc: "2.0",
            result: "0x0000000000000000000000000000000000000000000000a3307e346e3edab2c1"
          }
        ]
        |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    requests = [
      %{
        args: [],
        method_name: :name,
        contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56"
      },
      %{
        args: ["0x0000000000000000000000000000000000000000"],
        method_name: :balanceOf,
        contract_address: "0xe9e7cea3dedca5984780bafc599bd69add087d56"
      }
    ]

    assert [ok: "BUSD Token", ok: 3_010_313_572_023_648_563_905] = FirstApplication.execute_contract(requests, @erc20_abi)
  end
end
