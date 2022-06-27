defmodule Web3.ConfigTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule ExampleApplication do
    use Web3, rpc_endpoint: "http://localhost:8545"

    contract FirstContract, contract_address: "0x0000000000000000000000000000000000000000", abi_path: Path.join([__DIR__, "../support/fixtures/BUSD.abi.json"])
  end

  defmodule Example2Application do
    use Web3,
      rpc_endpoint: "http://localhost:8545",
      http: Web3.HTTP.Finch,
      http_options: []
  end

  defmodule Example3Application do
    Application.put_env(:web3, __MODULE__, chain_id: 56)
    Application.put_env(:web3, Example3Application.FirstContract, gas_limit: 15_000)

    use Web3,
      rpc_endpoint: "http://localhost:8545",
      http: Web3.HTTP.Finch,
      http_options: [],
      chain_id: 97

    contract FirstContract, contract_address: "0x0000000000000000000000000000000000000000", abi_path: Path.join([__DIR__, "../support/fixtures/BUSD.abi.json"])
  end

  describe "A Application Config" do
    test "should get application config with @default_config" do
      assert [
               {:middleware, [Web3.Middleware.Parser, Web3.Middleware.RequestInspector, Web3.Middleware.ResponseFormatter]},
               {:http, Web3.HTTP.HTTPoison},
               {:http_options, [recv_timeout: 60000, timeout: 60000, hackney: [pool: :web3]]},
               {:rpc_endpoint, "http://localhost:8545"}
             ] = ExampleApplication.config()
    end

    test "should get application config with http && http_options" do
      assert [
               {:middleware, [Web3.Middleware.Parser, Web3.Middleware.RequestInspector, Web3.Middleware.ResponseFormatter]},
               {:rpc_endpoint, "http://localhost:8545"},
               {:http, Web3.HTTP.Finch},
               {:http_options, []}
             ] = Example2Application.config()
    end

    test "should get application with config :web3" do
      assert [
               {:middleware, [Web3.Middleware.Parser, Web3.Middleware.RequestInspector, Web3.Middleware.ResponseFormatter]},
               {:rpc_endpoint, "http://localhost:8545"},
               {:http, Web3.HTTP.Finch},
               {:http_options, []},
               {:chain_id, 97}
             ] = Example3Application.config()
    end
  end

  describe "A Contract Config" do
    test "should get contract config with belong application env" do
      config_keys = ExampleApplication.FirstContract.config() |> Keyword.keys()
      assert [:middleware, :http, :http_options, :rpc_endpoint, :contract_address, :abi_path] = config_keys
    end

    test "should get contract config :web3" do
      config_keys = Example3Application.FirstContract.config() |> Keyword.keys()
      assert [:middleware, :rpc_endpoint, :http, :http_options, :chain_id, :contract_address, :abi_path] = config_keys
    end
  end
end
