defmodule Web3.Contract do
  @moduledoc """
  Smart contract functions executed by Dispatcher
  """

  require Logger

  alias Web3.Dispatcher

  @spec execute(Map.t() | Keyword.t(), Keyword.t(), Keyword.t()) :: {:ok, [{:ok, any()}, {:error, any()}]}
  def execute(request, abi, options) when is_map(request), do: execute([request], abi, options)

  def execute(requests, abi, options) do
    parsed_abi =
      abi
      |> Enum.map(&Web3.ABI.Compiler.parse_abi/1)
      |> Enum.reject(&is_nil/1)

    functions = Enum.into(parsed_abi, %{}, &{&1.name, &1})

    requests_with_index = Enum.with_index(requests)

    indexed_responses =
      requests_with_index
      |> Enum.map(fn {%{contract_address: contract_address, method_name: method_name} = request, index} ->
        args = Map.get(request, :args, [])

        function = define_function(functions, method_name)

        func_selector =
          function
          |> Web3.Type.Function.method_signature()
          |> Web3.keccak256()
          |> binary_part(0, 10)

        case function.state_mutability do
          value when value in [:pure, :view] ->
            tco = Web3.Type.Function.tco(args, function, func_selector, to: contract_address)
            block = Map.get(request, :block, :latest)

            %{id: index, jsonrpc: "2.0", method: :eth_call, params: [tco, block]}

          value when value in [:nonpayable, :payable] ->
            tco = Web3.Type.Function.tco(args, function, func_selector, Keyword.merge([to: contract_address], Map.to_list(request)))

            priv_key = Map.get(request, :priv_key, nil)
            {:ok, priv_key} = Web3.parse_privkey(priv_key)
            signed_txn = Web3.ABI.Signer.sign_transaction(tco, priv_key)

            %{id: index, jsonrpc: "2.0", method: :eth_sendRawTransaction, params: [signed_txn]}

          _ ->
            raise "Unsupported state mutability: #{function.state_mutability}"
        end
      end)
      |> build_payload(options)
      |> Dispatcher.dispatch()
      |> case do
        {:ok, responses} -> responses
        {:error, {:bad_gateway, _request_url}} -> raise "Bad gateway"
        {:error, reason} when is_atom(reason) -> raise Atom.to_string(reason)
        {:error, error} -> raise error
      end
      |> Enum.into(%{}, &{&1.id, &1})

    Enum.map(requests_with_index, fn {%{method_name: method_name}, index} ->
      indexed_responses[index]
      |> case do
        %{error: error} ->
          {index, {:error, error}}

        response ->
          function = define_function(functions, method_name)
          {^index, result} = decode_result(response, function)

          {index, result}
      end
    end)
  rescue
    error ->
      Enum.map(requests, fn _ -> format_error(error) end)
  end

  defp build_payload(params, options) do
    json_rpc_arguments = [
      http: Keyword.get(options, :http),
      http_options: Keyword.get(options, :http_options),
      rpc_endpoint: Keyword.get(options, :rpc_endpoint)
    ]

    %Dispatcher.Payload{
      json_rpc_arguments: json_rpc_arguments,
      request: params,
      method: :__skip_parser__,
      middleware: Keyword.get(options, :middleware)
    }
  end

  defp define_function(functions, target_method_name) do
    {_, function} =
      Enum.find(functions, fn {method_name, _func} ->
        method_name == target_method_name
      end)

    function
  end

  def decode_result(%{error: %{code: code, data: data, message: message}, id: id}), do: {id, {:error, "(#{code}) #{message} (#{data})"}}
  def decode_result(%{error: %{code: code, message: message}, id: id}), do: {id, {:error, "(#{code}) #{message}"}}

  def decode_result(%{id: id, result: result}, function) do
    return_types = function.outputs |> Enum.map(&elem(&1, 1))

    decoded_data =
      result
      |> Web3.Middleware.Parser.decode_value(return_types)
      |> Web3.Middleware.Parser.unwrap()

    {id, decoded_data}
  rescue
    MatchError ->
      {id, {:error, :invalid_data}}
  end

  # format error
  defp format_error(message) when is_binary(message), do: {:error, message}
  defp format_error(%{message: error_message}), do: format_error(error_message)
  defp format_error(error), do: format_error(Exception.message(error))
end
