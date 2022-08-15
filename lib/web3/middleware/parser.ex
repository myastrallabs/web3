defmodule Web3.Middleware.Parser do
  @moduledoc """
  Wrapping before_dispatch and after_dispatch the request to JSON RPC API.

  NOTE: Awkward naming
  """

  @behaviour Web3.Middleware

  require Logger

  alias Web3.Middleware.Pipeline
  import Pipeline

  def before_dispatch(%Pipeline{method: :__skip_parser__} = pipeline), do: pipeline

  def before_dispatch(%Pipeline{method: _method, args: [head | _tail] = args} = pipeline) when is_list(head) do
    args
    |> parse_args([])
    |> do_before_dispatch(pipeline)
  end

  def before_dispatch(%Pipeline{args: [_from.._to = _head | _tail] = args} = pipeline) do
    args
    |> parse_args([])
    |> do_before_dispatch(pipeline)
  end

  def before_dispatch(%Pipeline{method: method, args: args} = pipeline) do
    args = parse_args(args, [])
    request = %{id: 1, jsonrpc: "2.0", method: method, params: args}

    pipeline
    |> set_request(request)
  end

  def after_dispatch(%Pipeline{method: :__skip_parser__} = pipeline), do: pipeline

  def after_dispatch(%Pipeline{assigns: %{id_to_params: id_to_params}, response: {:ok, response}, return_fn: return_fn} = pipeline) when is_list(response) do
    result = from_responses(response, id_to_params, return_fn)

    pipeline
    |> respond({:ok, result})
  end

  def after_dispatch(%Pipeline{response: {:ok, response}, return_fn: return_fn} = pipeline) do
    result =
      response
      |> decode_value(return_fn)
      |> unwrap()

    pipeline
    |> respond({:ok, result})
  end

  def after_failure(%Pipeline{method: :__skip_parser__} = pipeline), do: pipeline

  def after_failure(%Pipeline{} = pipeline) do
    Logger.error("Request Failed: #{inspect(pipeline)}")
    pipeline
  end

  def do_before_dispatch([head | tail], %Pipeline{method: method} = pipeline) when is_list(head) do
    id_to_params = head |> id_to_params()
    request = id_to_params |> Enum.map(fn {id, item} -> %{id: id, jsonrpc: "2.0", method: method, params: [item | tail]} end)

    pipeline
    |> assign(:id_to_params, id_to_params)
    |> set_request(request)
  end

  def parse_args([head | tail] = _args, result) do
    parse_result = do_parse_args(head)
    parse_args(tail, [parse_result | result])
  end

  def parse_args([], result), do: Enum.reverse(result)

  # parse eth_getLogs
  defp do_parse_args(%{fromBlock: from_block, toBlock: to_block} = entry) do
    entry
    |> Map.put(:fromBlock, Web3.to_hex(from_block))
    |> Map.put(:toBlock, Web3.to_hex(to_block))
  end

  defp do_parse_args(entry) when is_binary(entry), do: entry
  defp do_parse_args(entry) when is_integer(entry), do: Web3.to_hex(entry)
  defp do_parse_args(entry) when is_list(entry), do: Enum.map(entry, &Web3.to_hex/1)

  defp do_parse_args(_from.._to = entry) do
    {from, to} = Enum.min_max(entry)

    from..to
    |> Enum.to_list()
    |> Enum.map(&Web3.to_hex/1)
  end

  defp do_parse_args(entry), do: entry

  defp from_responses(responses, id_to_params, return_fn) do
    responses
    |> Enum.map(&from_response(&1, id_to_params, return_fn))
    |> Enum.reduce(
      %{result: [], params: [], errors: []},
      fn
        {:ok, {param, decode_data}}, %{result: result, params: params} = acc ->
          %{
            acc
            | params: [param | params],
              result: [decode_data | result]
          }

        {:error, reason}, %{errors: errors} = acc ->
          %{acc | errors: [reason | errors]}
      end
    )
  end

  defp from_response(%{id: id, result: result}, id_to_params, return_fn) when is_map(id_to_params) do
    param = Map.fetch!(id_to_params, id)
    decode_data = decode_value(result, return_fn)

    {:ok, {param, decode_data}}
  end

  defp from_response(%{id: id, error: result}, id_to_params, _return_fn) when is_map(id_to_params) do
    param = Map.fetch!(id_to_params, id)
    {:error, %{param: param, error: result}}
  end

  defp id_to_params(params) do
    params
    |> Stream.with_index()
    |> Enum.into(%{}, fn {params, id} -> {id, params} end)
  end

  def decode_value({:error, _} = return_value, _return_types), do: return_value
  def decode_value(nil, _return_types), do: nil
  def decode_value(return_value, :raw), do: return_value
  def decode_value(return_value, :int), do: Web3.to_integer(return_value)
  def decode_value(return_value, decoder) when is_function(decoder, 1), do: decoder.(return_value)

  def decode_value("0x" <> return_value, return_types) do
    {:ok, data} = Base.decode16(return_value, case: :mixed)
    Web3.ABI.decode(data, return_types)
  end

  def unwrap([]), do: nil
  def unwrap({:ok, value}), do: unwrap(value)
  def unwrap([value]), do: value
  # def unwrap(values) when is_list(values), do: List.to_tuple(values)
  def unwrap(value), do: value
end
