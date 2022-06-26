defmodule Web3.ABI.TypeDecoder do
  @moduledoc false

  require Logger

  def decode_data(data, types) do
    with {:ok, values, _offset} <- decode_data(data, types, 0) do
      {:ok, values}
    end
  end

  def decode_data(data, types, offset) do
    types
    |> Enum.reduce_while({offset, []}, fn
      type, {off, acc} ->
        case decode_type(data, type, off) do
          {:ok, value, new_off} ->
            {:cont, {new_off, [value | acc]}}

          :error ->
            {:halt, :error}
        end
    end)
    |> case do
      :error -> :error
      {new_offset, values} -> {:ok, Enum.reverse(values), new_offset}
    end
  end

  @spec decode_type(binary(), term(), binary()) :: {:ok, term(), binary()} | :error
  def decode_type(data, :address, offset) do
    <<_::bytes-size(offset), address::256, _::binary()>> = data

    case Web3.Type.Address.cast(address) do
      {:ok, address} ->
        {:ok, address, offset + 32}

      _ ->
        :error
    end
  end

  def decode_type(data, {:uint, _size}, offset) do
    <<_::bytes-size(offset), uint::256, _::binary()>> = data
    {:ok, uint, offset + 32}
  end

  def decode_type(data, :bool, offset) do
    <<_::bytes-size(offset), bool::256, _::binary()>> = data
    {:ok, bool > 0, offset + 32}
  end

  for i <- 1..32 do
    def decode_type(data, {:bytes, unquote(i)}, offset) do
      <<_::bytes-size(offset), bytes::bytes-size(unquote(i)), _padding::bytes-size(unquote(32 - i))>> = data

      case Web3.Type.Bytes.cast(bytes) do
        {:ok, bytes} ->
          {:ok, bytes, offset + 32}

        _ ->
          :error
      end
    end
  end

  for i <- 1..31 do
    def decode_type(data, {:int, unquote(i * 8)}, offset) do
      <<_::bytes-size(offset), _::signed-unquote(256 - i * 8), n::signed-unquote(i * 8)>> = data
      {:ok, n, offset + 32}
    end
  end

  def decode_type(data, {:int, 256}, offset) do
    <<_::bytes-size(offset), int::signed-256, _::binary()>> = data
    {:ok, int, offset + 32}
  end

  def decode_type(data, {:tuple, inner_types}, offset) do
    with {:ok, values, new_offset} <- decode_data(data, inner_types, offset) do
      {:ok, List.to_tuple(values), new_offset}
    end
  end

  def decode_type(data, :bytes, offset) do
    <<_::bytes-size(offset), bytes_offset::256, _::binary()>> = data
    <<_skipped::bytes-size(bytes_offset), len::256, bytes::bytes-size(len), _::bytes()>> = data

    case Web3.Type.Data.cast(bytes) do
      {:ok, bytes} ->
        {:ok, bytes, offset + 32}

      _ ->
        :error
    end
  end

  def decode_type(data, :string, offset) do
    <<_::bytes-size(offset), str_offset::256, _::bytes()>> = data
    <<_skipped::bytes-size(str_offset), len::256, string::bytes-size(len), _::bytes()>> = data
    {:ok, string, offset + 32}
  end

  def decode_type(data, {:array, inner_type}, offset) do
    <<_::bytes-size(offset), array_offset::256, _::binary()>> = data
    <<_skipped::bytes-size(array_offset), len::256, rest::bytes()>> = data

    case decode_data(rest, List.duplicate(inner_type, len), 0) do
      {:ok, values, _inner_offset} ->
        {:ok, values, offset + 32}

      _ ->
        :error
    end
  end

  def decode_type(data, {:array, inner_type, len}, offset) do
    decode_data(data, List.duplicate(inner_type, len), offset)
  end

  # TODO
  def decode_type(_, type, _data) do
    throw({:unknow_type, type})
  end
end
