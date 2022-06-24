defmodule Web3 do
  @moduledoc false

  use Web3.Utils

  alias Web3.HTTP

  defmacro __using__(opts) do
    quote do
      require Logger

      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)

      def name, do: unquote(opts[:name])
      def chain_id, do: unquote(opts[:chain_id])
      def json_rpc_arguments, do: unquote(opts[:json_rpc_arguments])

      @doc "eth_getBalance/2"
      def eth_getBalance(address, block_identifier) do
        %{id: 1, jsonrpc: "2.0", method: "eth_getBalance", params: [address, block_identifier]}
        |> json_rpc(json_rpc_arguments())
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      IO.inspect("__before_compile__")
    end
  end

  def json_rpc(payload, json_rpc_arguments), do: HTTP.json_rpc(payload, json_rpc_arguments)
end
