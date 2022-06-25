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

      @default_middleware [
        Web3.Middleware.Parser
        # Web3.Middleware.Logger,
      ]

      @default_methods [
        {:eth_blockNumber, args: 0, return_fn: :hex},
        {:eth_getBalance, args: 2, return_fn: :hex}
      ]

      @app_id unquote(opts[:id])
      @chain_id unquote(opts[:chain_id])
      @json_rpc_args unquote(opts[:json_rpc_arguments])

      def id, do: @app_id
      def chain_id, do: @chain_id
      def json_rpc_arguments, do: @json_rpc_args
    end
  end

  defmacro __before_compile__(env) do
    default_middleware =
      env.module
      |> Module.get_attribute(:default_middleware, [])
      |> Enum.reverse()

    registered_middleware =
      env.module
      |> Module.get_attribute(:registered_middleware, [])
      |> Enum.reverse()

    middleware =
      Enum.reduce(default_middleware, registered_middleware, fn middleware, acc ->
        [middleware | acc]
      end)

    app_id = env.module |> Module.get_attribute(:app_id)
    chain_id = env.module |> Module.get_attribute(:chain_id)
    json_rpc_args = env.module |> Module.get_attribute(:json_rpc_args)

    default_methods =
      env.module
      |> Module.get_attribute(:default_methods, [])
      |> Enum.reverse()

    registered_methods =
      env.module
      |> Module.get_attribute(:registered_methods, [])
      |> Enum.reverse()

    methods = default_methods ++ registered_methods

    dispatch_defs =
      for {method, opts} <- methods do
        new_opts =
          opts
          |> Keyword.put(:app_id, app_id)
          |> Keyword.put(:chain_id, chain_id)
          |> Keyword.put(:json_rpc_args, json_rpc_args)
          |> Keyword.put(:middleware, middleware)

        defdispatch(method, new_opts)
      end

    quote generated: true do
      unquote(dispatch_defs)
    end
  end

  def json_rpc(payload, json_rpc_arguments), do: HTTP.json_rpc(payload, json_rpc_arguments)

  defp defdispatch(method, opts \\ []) do
    arg_number = Keyword.get(opts, :args, 0)

    method_name = Keyword.get(opts, :name, method)
    return_fn = Keyword.get(opts, :return_fn, :raw)
    middleware = Keyword.get(opts, :middleware, [])
    json_rpc_args = Keyword.get(opts, :json_rpc_args)
    chain_id = Keyword.get(opts, :chain_id, 0)
    app_id = Keyword.get(opts, :app_id)

    args = Macro.generate_arguments(arg_number, __MODULE__)

    quote do
      def unquote(method_name)(unquote_splicing(args)) do
        payload = %Web3.Dispatcher.Payload{
          app_id: unquote(app_id),
          json_rpc_args: unquote(json_rpc_args),
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

  defmacro middleware(middleware_module) do
    quote do
      @registered_middleware unquote(middleware_module)
    end
  end

  defmacro dispatch(method, opts) do
    :ok = parse_method(method)
    opts = parse_opts(opts, [])

    quote do
      @registered_methods {unquote(method), unquote(opts)}
    end
  end

  @register_methods [
    :eth_blockNumber,
    :eth_getBalance
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

  defp parse_opts([{:name, alias} | opts], result) when is_binary(alias) do
    parse_opts(opts, [{:name, String.to_atom(alias)} | result])
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
