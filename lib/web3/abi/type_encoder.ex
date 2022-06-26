defmodule Web3.ABI.TypeEncoder do
  @moduledoc false

  require Logger

  @spec encode(term(), Web3.types()) :: binary()
  def encode(value, type)

  def encode(address, :address) do
    {:ok, %{bytes: bytes}} = Web3.Type.Address.cast(address)
    <<0::96, bytes::bytes()>>
  end

  def encode(integer, {:uint, bits}) when is_integer(integer) do
    padding = 256 - bits
    <<0::size(padding), integer::size(bits)>>
  end

  def encode(integer, {:int, bits}) when is_integer(integer) do
    padding = 256 - bits

    if integer >= 0 do
      <<0::size(padding), integer::signed-size(bits)>>
    else
      <<-1::size(padding), integer::signed-size(bits)>>
    end
  end

  def encode(list, {:array, inner_type}) when is_list(list) do
    data =
      for value <- list, into: <<>> do
        encode(value, inner_type)
      end

    encode(length(list), {:uint, 256}) <> data
  end

  def encode(list, {:array, inner_type, n}) when is_list(list) and length(list) == n do
    for value <- list, into: <<>> do
      encode(value, inner_type)
    end
  end

  def encode(tuple, {:tuple, inner_types}) when is_tuple(tuple) and is_list(inner_types) and tuple_size(tuple) == length(inner_types) do
    for {value, inner_type} <- tuple |> Tuple.to_list() |> Enum.zip(inner_types), into: <<>> do
      encode(value, inner_type)
    end
  end

  # TODO: more types
  def encode(value, type) do
    Logger.error("Unsupported type #{inspect(type)}: #{inspect(value)}")
    <<0::256>>
  end

  @spec pack([binary()], [Web3.types()]) :: binary()

  def pack(encoded_inputs, input_types) do
    pack(encoded_inputs, input_types, length(encoded_inputs) * 32, <<>>, <<>>)
  end

  defp pack([], [], _base_offset, inplace_data, data) do
    inplace_data <> data
  end

  defp pack([encoded | encoded_inputs], [{:array, _} | input_types], base_offset, inplace_data, data) do
    offset = encode(base_offset + byte_size(data), {:uint, 256})
    pack(encoded_inputs, input_types, base_offset, inplace_data <> offset, data <> encoded)
  end

  defp pack([encoded | encoded_inputs], [type | input_types], base_offset, inplace_data, data) do
    pack(encoded_inputs, input_types, base_offset + type_size(type) - 32, inplace_data <> encoded, data)
  end

  defp type_size({:tuple, inner_types}) do
    inner_types
    |> Enum.map(&type_size/1)
    |> Enum.sum()
  end

  defp type_size(_), do: 32
end
