defmodule Web3 do
  @moduledoc """
  Web3 is high level, user-friendly Ethereum JSON-RPC Client.

  ## Provides:

    - Multi Chain Ethereum JSON-RPC Client
    - Interacting smart contracts

  """

  use Web3.Utils

  alias Web3.{HTTP, Dispatcher}

  defmacro __using__(opts) do
    quote do
      require Logger

      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :registered_middleware, accumulate: true)
      Module.register_attribute(__MODULE__, :registered_methods, accumulate: true)
      Module.register_attribute(__MODULE__, :registered_contracts, accumulate: true)

      @default_middleware [
        Web3.Middleware.Parser,
        Web3.Middleware.RequestInspector,
        Web3.Middleware.ResponseFormatter
      ]

      @default_methods [
        {:eth_blockNumber, return_fn: :int},
        {:eth_getBalance, args: 2, return_fn: :int},
        {:eth_gasPrice, return_fn: :int},
        {:eth_getTransactionReceipt, args: 1},
        {:eth_getBlockByHash, args: 2},
        {:eth_getBlockByNumber, args: 2},
        {:eth_getTransactionCount, args: 2, return_fn: :int},
        {:eth_getLogs, args: 1},
        {:eth_sendRawTransaction, args: 1},
        {:eth_getCode, args: 2},
        {:net_version, return_fn: :integer},
        {:eth_getTransactionByHash, args: 1},
        {:eth_getUncleByBlockHashAndIndex, args: 2},
        {:eth_getTransactionByBlockHashAndIndex, args: 2},
        {:eth_getTransactionByBlockNumberAndIndex, args: 2},
        {:eth_getBlockTransactionCountByHash, args: 1, return_fn: :int},
        {:eth_getBlockTransactionCountByNumber, args: 1, return_fn: :int}
      ]

      @default_config [
        http: Web3.HTTP.HTTPoison,
        http_options: [recv_timeout: 60_000, timeout: 60_000, hackney: [pool: :web3]]
      ]

      @config compile_config(__MODULE__, @default_config, unquote(opts))
    end
  end

  defmacro __before_compile__(env) do
    # middleware
    default_middleware = env.module |> Module.get_attribute(:default_middleware, []) |> Enum.reverse()
    registered_middleware = env.module |> Module.get_attribute(:registered_middleware, []) |> Enum.reverse()
    middleware = Enum.reduce(default_middleware, registered_middleware, fn middleware, acc -> [middleware | acc] end)

    # methods
    default_methods = env.module |> Module.get_attribute(:default_methods, [])
    registered_methods = env.module |> Module.get_attribute(:registered_methods, [])
    methods = default_methods ++ registered_methods

    # contracts
    registered_contracts = env.module |> Module.get_attribute(:registered_contracts, [])

    global_config =
      env.module
      |> Module.get_attribute(:config)
      |> Keyword.put(:middleware, middleware)

    dispatch_defs =
      for {method, opts} <- methods do
        new_opts =
          global_config
          |> Keyword.merge(opts)

        defdispatch(method, new_opts)
      end

    contract_defs =
      for {contract_name, opts} <- registered_contracts do
        # support top-level module nameing
        is_top_module? = contract_name |> Atom.to_string() |> String.split(".") |> hd() |> Kernel.===("Elixir")

        module_name =
          if is_top_module? do
            contract_name
          else
            Module.concat(__CALLER__.module, contract_name)
          end

        new_opts =
          global_config
          |> Keyword.merge(opts)

        defcontract(module_name, new_opts)
      end

    quote generated: true do
      # dispatch
      unquote(dispatch_defs)

      # contract
      unquote(contract_defs)

      def config(), do: unquote(global_config)
      # contracts
      def contracts(), do: unquote(registered_contracts)
      # methods
      def methods(), do: unquote(methods)

      # middleware
      def middleware(), do: unquote(middleware)

      @doc """
      Execute Contract

      TODO [ ] add contract doc

      """
      def execute_contract(requests, abi) do
        Web3.Contract.execute(requests, abi, unquote(global_config))
      end
    end
  end

  def json_rpc(payload, json_rpc_arguments), do: HTTP.json_rpc(payload, json_rpc_arguments)

  defp defdispatch(method, opts \\ []) do
    # validate method
    # :ok = parse_method(method)

    arg_number = Keyword.get(opts, :args, 0)
    method_name = Keyword.get(opts, :name, method)
    return_fn = Keyword.get(opts, :return_fn, :raw)
    middleware = Keyword.get(opts, :middleware, [])

    json_rpc_arguments = [
      http: Keyword.get(opts, :http),
      http_options: Keyword.get(opts, :http_options, []),
      rpc_endpoint: Keyword.get(opts, :rpc_endpoint)
    ]

    args = Macro.generate_arguments(arg_number, __MODULE__)

    quote do
      def unquote(method_name)(unquote_splicing(args)) do
        payload = %Dispatcher.Payload{
          json_rpc_arguments: unquote(json_rpc_arguments),
          args: unquote(args),
          method_name: unquote(method_name),
          method: unquote(method),
          return_fn: unquote(return_fn),
          middleware: unquote(middleware)
        }

        Dispatcher.dispatch(payload)
      end
    end
  end

  defp defcontract(contract_name, opts \\ []) do
    quote do
      defmodule unquote(contract_name) do
        use Web3.ABI.Compiler, unquote(opts)
      end
    end
  end

  defmacro middleware(middleware_module) do
    quote do
      @registered_middleware unquote(middleware_module)
    end
  end

  defmacro contract(contract_name, opts) do
    quote do
      @registered_contracts {unquote(contract_name), unquote(opts)}
    end
  end

  defmacro dispatch(method, opts) do
    # :ok = parse_method(method)

    opts = parse_opts(opts, [])

    quote do
      @registered_methods {unquote(method), unquote(opts)}
    end
  end

  def compile_config(module_name, default_config, opts) do
    config = Application.get_env(:web3, module_name, [])

    default_config
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
  end

  @register_methods [
    :eth_blockNumber,
    :eth_getBalance,
    :eth_gasPrice,
    :eth_getTransactionReceipt
  ]

  def parse_method(method) do
    unless method in @register_methods do
      raise """
      unexpected dispatch parameter "#{method}"
      available params are: #{Enum.map_join(@register_methods, ", ", &to_string/1)}
      """
    else
      :ok
    end
  end

  @register_params [
    :name,
    :args,
    :return_fn
  ]

  defp parse_opts([{:name, alias_name} | opts], result) when is_binary(alias_name) do
    parse_opts(opts, [{:name, String.to_atom(alias_name)} | result])
  end

  defp parse_opts([{param, value} | opts], result) when param in @register_params do
    parse_opts(opts, [{param, value} | result])
  end

  defp parse_opts([{param, _value} | _opts], _result) do
    raise """
    unexpected dispatch parameter "#{param}"
    available params are: #{Enum.map_join(@register_params, ", ", &to_string/1)}
    """
  end

  defp parse_opts([], result), do: result
end
