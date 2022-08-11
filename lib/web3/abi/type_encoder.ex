defmodule Web3.ABI.TypeEncoder do
  @moduledoc false

  require Logger
  import Web3.ABI.Types

  @spec encode_type(term(), Web3.ABI.Types.types()) :: binary()
  def encode_type(value, type)

  def encode_type(address, :address) do
    {:ok, %{bytes: bytes}} = Web3.Type.Address.cast(address)
    <<0::96, bytes::bytes()>>
  end

  def encode_type(true, :bool), do: <<1::256>>
  def encode_type(false, :bool), do: <<0::256>>

  def encode_type(integer, {:uint, bits}) when is_integer(integer) do
    padding = 256 - bits
    <<0::size(padding), integer::size(bits)>>
  end

  def encode_type(integer, {:int, bits}) when is_integer(integer) do
    padding = 256 - bits

    if integer >= 0 do
      <<0::size(padding), integer::signed-size(bits)>>
    else
      <<-1::size(padding), integer::signed-size(bits)>>
    end
  end

  def encode_type(bytes_n, {:bytes, n}) when is_binary(bytes_n) and n in 1..32 and byte_size(bytes_n) == n do
    padding = 32 - n
    <<bytes_n::bytes(), 0::padding*8>>
  end

  def encode_type("0x" <> bytes_n, {:bytes, n}) when is_binary(bytes_n) and n in 1..32 and byte_size(bytes_n) == n * 2 do
    case Base.decode16(bytes_n, case: :mixed) do
      {:ok, bytes} ->
        padding = 32 - n
        <<bytes::bytes(), 0::padding*8>>

      _ ->
        :error
    end
  end

  def encode_type(binary, type) when type in [:bytes, :string] and is_binary(binary) do
    len = byte_size(binary)
    pad_len = calc_padding(len)
    encode_type(len, {:uint, 256}) <> binary <> <<0::pad_len*8>>
  end

  def encode_type(string, :string) when is_binary(string) do
    len = byte_size(string)
    pad_len = calc_padding(len)
    encode_type(len, {:uint, 256}) <> string <> <<0::pad_len*8>>
  end

  def encode_type(list, {:array, inner_type}) when is_list(list) do
    len = length(list)
    data = encode(list, List.duplicate(inner_type, len))
    encode_type(len, {:uint, 256}) <> data
  end

  def encode_type(list, {:array, inner_type, n}) when is_list(list) and length(list) == n do
    if dynamic_type?(inner_type) do
      encode(list, List.duplicate(inner_type, n))
    else
      for value <- list, into: <<>> do
        encode_type(value, inner_type)
      end
    end
  end

  def encode_type(tuple, {:tuple, inner_types}) when is_tuple(tuple) and is_list(inner_types) and tuple_size(tuple) == length(inner_types) do
    encode(Tuple.to_list(tuple), inner_types)
  end

  def encode_type(tuple, {:tuple, inner_types}) when length(tuple) == length(inner_types) do
    encode(tuple, inner_types)
  end

  # TODO: more types
  def encode_type(value, type) do
    Logger.error("Unsupported type #{inspect(type)}: #{inspect(value)}")
    <<0::256>>
  end

  @spec encode([term()], [ABX.types()]) :: binary()
  def encode(values, types) when length(values) == length(types) do
    tail_offset =
      types
      |> Enum.map(&head_size/1)
      |> Enum.sum()

    {head, tail} =
      Enum.zip(values, types)
      |> Enum.reduce({"", ""}, fn {value, type}, {head, tail} ->
        encoded = encode_type(value, type)

        if dynamic_type?(type) do
          offset = encode_type(tail_offset + byte_size(tail), {:uint, 256})
          {head <> offset, tail <> encoded}
        else
          {head <> encoded, tail}
        end
      end)

    head <> tail
  end

  defp calc_padding(n) do
    remaining = rem(n, 32)

    if remaining == 0 do
      0
    else
      32 - remaining
    end
  end
end
