defmodule Web3.ABI.Compiler do
  @moduledoc """
  Compile for ABI json file

  ## Example of ABI Compiler

      defmodule SimpleContract do
        use Web3.ABI.Compiler,
          id: :simple_contract,
          chain_id: 56,
          json_rpc_arguments: [
            url: "https://bsc-dataseed4.ninicoin.io/",
            http: Web3.HTTP.HTTPoison,
            http_options: [
              recv_timeout: :timer.minutes(1),
              timeout: :timer.minutes(1),
              hackney: [pool: :web3]
            ]
          ],
          contract_address: "0x0000000000000000000000000000000000000000"",
      end

  """

  require Logger

  alias Web3.Type.{Event, Function, Constructor}

  defmacro __using__(opts) do
    alias Web3.Type.{Event, Function}

    abi_file = opts[:abi_file]
    abis = parse_abi_file(abi_file)
    contract_address = opts[:contract_address]

    event_defs =
      for %Event{} = event_abi <- abis do
        defevent(event_abi)
      end

    function_defs =
      for %Function{} = function_abi <- abis do
        deffunction(function_abi, opts)
      end

    quote do
      @app_id unquote(opts[:id])
      @chain_id unquote(opts[:chain_id])
      @json_rpc_args unquote(opts[:json_rpc_arguments])
      @external_resource unquote(abi_file)
      @abis unquote(Macro.escape(abis))
      @contract_address unquote(contract_address)

      @middleware [
        Web3.Middleware.Parser,
        Web3.Middleware.RequestInspector,
        Web3.Middleware.ResponseFormatter
      ]

      def abis(), do: @abis
      def address(), do: @contract_address

      Module.register_attribute(__MODULE__, :events, accumulate: true)
      unquote(event_defs)

      @events_lookup Map.new(@events)

      def lookup(event_signature) do
        @events_lookup[event_signature]
      end

      def decode_event(%{topics: [event_signature | _]} = log) do
        case lookup(event_signature) do
          nil ->
            nil

          event ->
            Web3.Type.Event.decode_log(event, log)
        end
      end

      unquote(function_defs)
    end
  end

  # defmacro __before_compile__(env) do
  #   default_middleware =
  #     env.module
  #     |> Module.get_attribute(:default_middleware, [])
  #     |> Enum.reverse()

  #   registered_middleware =
  #     env.module
  #     |> Module.get_attribute(:registered_middleware, [])
  #     |> Enum.reverse()

  #   middleware =
  #     Enum.reduce(default_middleware, registered_middleware, fn middleware, acc ->
  #       [middleware | acc]
  #     end)

  #   app_id = env.module |> Module.get_attribute(:app_id)
  #   abis = env.module |> Module.get_attribute(:abis)
  #   chain_id = env.module |> Module.get_attribute(:chain_id)
  #   json_rpc_args = env.module |> Module.get_attribute(:json_rpc_args)

  #   opts = [
  #     middleware: middleware,
  #     json_rpc_args: json_rpc_args,
  #     chain_id: chain_id,
  #     app_id: app_id
  #   ]

  #   function_defs =
  #     for %Function{} = function_abi <- abis do
  #       deffunction(function_abi, opts)
  #     end

  #   quote generated: true do
  #     unquote(function_defs)
  #   end
  # end

  # defmacro middleware(middleware_module) do
  #   quote do
  #     @registered_middleware unquote(middleware_module)
  #   end
  # end

  def parse_abi_file(file_name) do
    file_name
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
    |> Enum.map(&parse_abi/1)
    |> Enum.reject(&is_nil/1)
  end

  def parse_abi(%{type: "constructor"} = abi) do
    %Constructor{
      inputs: parse_params(abi.inputs),
      payable: abi[:payable],
      state_mutability: parse_state_mutability(abi[:stateMutability])
    }
  end

  def parse_abi(%{type: "event"} = abi) do
    inputs = parse_event_params(abi.name, abi.inputs)

    %Event{
      name: String.to_atom(abi.name),
      anonymous: abi.anonymous,
      inputs: inputs,
      signature: calc_signature(abi.name, inputs)
    }
  end

  def parse_abi(%{type: "function"} = abi) do
    %Function{
      name: String.to_atom(abi.name),
      inputs: parse_params(abi.inputs),
      outputs: parse_params(abi.outputs),
      constant: abi[:constant],
      payable: abi[:payable],
      state_mutability: parse_state_mutability(abi[:stateMutability])
    }
  end

  # receive & fallback
  def parse_abi(%{type: _}) do
    nil
  end

  def calc_signature(name, inputs) do
    [name, ?(, inputs |> Enum.map(&Web3.ABI.type_name(elem(&1, 1))) |> Enum.join(","), ?)]
    |> IO.iodata_to_binary()
    |> ExKeccak.hash_256()
    |> Web3.ABI.to_hex()
  end

  def parse_event_params(event_name, type_defs) do
    type_defs
    |> Enum.map(fn %{name: name, indexed: indexed} = type_def ->
      if name == "" do
        Logger.error("Event #{inspect(event_name)}: empty param name")
      end

      {String.to_atom(name), Web3.ABI.parse_type(type_def), [indexed: indexed]}
    end)
  end

  def parse_params(type_defs) do
    type_defs
    |> Enum.map(fn %{name: name} = type_def ->
      param =
        name
        |> String.trim_leading("_")
        |> String.to_atom()

      {param, Web3.ABI.parse_type(type_def)}
    end)
  end

  def parse_state_mutability("view"), do: :view
  def parse_state_mutability("pure"), do: :pure
  def parse_state_mutability("payable"), do: :payable
  def parse_state_mutability("nonpayable"), do: :nonpayable
  def parse_state_mutability(_), do: :view

  def defevent(%Web3.Type.Event{} = event) do
    quote do
      use Web3.Type.Event, event: unquote(event)
    end
  end

  def deffunction(%Web3.Type.Function{} = function, opts \\ []) do
    quote do
      use Web3.Type.Function, function: unquote(function), opts: unquote(opts)
    end
  end
end