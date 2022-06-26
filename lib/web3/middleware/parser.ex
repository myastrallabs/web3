defmodule Web3.Middleware.Parser do
  @moduledoc """
  Wrapping before_dispatch and after_dispatch the request to JSON RPC API.

  NOTE: Awkward naming
  """

  @behaviour Web3.Middleware

  require Logger

  alias Web3.Middleware.Pipeline
  import Pipeline

  def before_dispatch(%Pipeline{method: method, args: [head | tail]} = pipeline) when is_list(head) do
    id_to_params = head |> id_to_params()
    request = id_to_params |> Enum.map(fn {id, item} -> %{id: id, jsonrpc: "2.0", method: method, params: [item | tail]} end)

    pipeline
    |> assign(:id_to_params, id_to_params)
    |> set_request(request)
  end

  def before_dispatch(%Pipeline{method: method, args: args} = pipeline) do
    request = %{id: 1, jsonrpc: "2.0", method: method, params: args}

    pipeline
    |> set_request(request)
  end

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

  def after_failure(%Pipeline{} = pipeline) do
    Logger.info("Request Failed")
    pipeline
  end

  defp from_responses(responses, id_to_params, return_fn) do
    responses
    |> Enum.map(&from_response(&1, id_to_params, return_fn))
    |> Enum.reduce(
      %{params_list: [], errors: []},
      fn
        {:ok, params}, %{params_list: params_list} = acc ->
          %{acc | params_list: [params | params_list]}

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

  defp id_to_params(params_list) do
    params_list
    |> Stream.with_index()
    |> Enum.into(%{}, fn {params, id} -> {id, params} end)
  end

  def decode_value(nil, _return_types), do: nil
  def decode_value(return_value, :raw), do: return_value
  def decode_value(return_value, :integer), do: String.to_integer(return_value)
  def decode_value("0x" <> return_value, :hex), do: String.to_integer(return_value, 16)
  def decode_value(return_value, decoder) when is_function(decoder, 1), do: decoder.(return_value)

  def decode_value("0x" <> return_value, return_types) do
    {:ok, data} = Base.decode16(return_value, case: :mixed)
    Web3.ABI.TypeDecoder.decode_data(data, return_types)
  end

  defp unwrap([]), do: nil
  defp unwrap({:ok, value}), do: unwrap(value)
  defp unwrap([value]), do: value
  defp unwrap(values) when is_list(values), do: List.to_tuple(values)
  defp unwrap(value), do: value
end
