defmodule Web3 do
  @moduledoc false

  use Web3.Utils

  alias Web3.Dispatcher
  alias Web3.HTTP

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
        # Web3.Middleware.Logger
      ]

      @default_methods [
        {:eth_blockNumber, return_fn: :hex},
        {:eth_getBalance, args: 2, return_fn: :hex},
        {:eth_gasPrice, return_fn: :hex},
        {:eth_getTransactionReceipt, args: 1},
        {:eth_getBlockByHash, args: 2},
        {:eth_getBlockByNumber, args: 2},
        {:eth_getTransactionCount, args: 2, return_fn: :hex},
        {:eth_getLogs, args: 1},
        {:eth_sendRawTransaction, args: 1}
      ]

      @opts unquote(opts)
      @app_id unquote(opts[:id])
      @chain_id unquote(opts[:chain_id])
      @json_rpc_arguments unquote(opts[:json_rpc_arguments])

      def id, do: @app_id
      def chain_id, do: @chain_id
      def json_rpc_arguments, do: @json_rpc_arguments
    end
  end

  defmacro __before_compile__(env) do
    global_opts = env.module |> Module.get_attribute(:opts)

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

    dispatch_defs =
      for {method, opts} <- methods do
        new_opts =
          global_opts
          |> Keyword.merge(opts)
          |> Keyword.put(:middleware, middleware)

        defdispatch(method, new_opts)
      end

    contract_defs =
      for {contract_name, opts} <- registered_contracts do
        contract_name = Module.concat(__CALLER__.module, contract_name)

        new_opts =
          global_opts
          |> Keyword.merge(opts)
          |> Keyword.put(:middleware, middleware)

        defcontract(contract_name, new_opts)
      end

    quote generated: true do
      unquote(contract_defs)
      unquote(dispatch_defs)
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
    json_rpc_arguments = Keyword.get(opts, :json_rpc_arguments)
    chain_id = Keyword.get(opts, :chain_id, 0)
    app_id = Keyword.get(opts, :app_id)

    args = Macro.generate_arguments(arg_number, __MODULE__)

    quote do
      def unquote(method_name)(unquote_splicing(args)) do
        payload = %Web3.Dispatcher.Payload{
          app_id: unquote(app_id),
          json_rpc_arguments: unquote(json_rpc_arguments),
          chain_id: unquote(chain_id),
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
