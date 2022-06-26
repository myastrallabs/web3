defmodule Web3.Middleware.ResponseFormatter do
  @moduledoc false

  @behaviour Web3.Middleware

  require Logger

  alias Web3.Middleware.Pipeline

  @include_methods [
    :eth_getLogs,
    :eth_getTransactionReceipt,
    :eth_getBlockByHash
  ]

  def before_dispatch(%Pipeline{} = pipeline), do: pipeline

  def after_dispatch(%Pipeline{method: method, response: {:ok, response}} = pipeline) when method in @include_methods do
    result = format_response(response)

    pipeline
    |> Pipeline.respond({:ok, result})
  end

  def after_dispatch(%Pipeline{} = pipeline), do: pipeline

  def after_failure(%Pipeline{} = pipeline), do: pipeline

  ## Private Methods

  defp format_response(entries) when is_list(entries), do: Enum.map(entries, &format_response/1)
  defp format_response(entry) when is_map(entry), do: Enum.into(entry, %{}, &do_format_response/1)
  defp format_response(result), do: result

  defp do_format_response({key, _} = entry) when key in ~w(address blockHash data removed topics transactionHash type)a, do: entry

  defp do_format_response({key, quantity}) when key in ~w(number difficulty blockNumber logIndex transactionIndex transactionLogIndex gas gasPrice nonce gasLimit gasUsed cumulativeGasUsed status)a do
    if is_nil(quantity) do
      {key, nil}
    else
      {key, Web3.to_integer(quantity)}
    end
  end

  defp do_format_response({key, value} = _entry) when is_list(value), do: {key, format_response(value)}
  defp do_format_response(entry), do: entry
end
