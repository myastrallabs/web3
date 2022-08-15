defmodule Web3.ABI.TypeDecoder do
  @moduledoc false

  require Logger

  import Web3.ABI.Types

  @spec decode_type(binary(), term(), integer()) :: {:ok, term()} | :error
  def decode_type(data, type, offset \\ 0)

  def decode_type(data, :address, offset) do
    <<_::bytes-size(offset), address::256, _::binary()>> = data
    Web3.Type.Address.cast(address)
  end

  def decode_type(data, :bool, offset) do
    <<_::bytes-size(offset), bool::256, _::binary()>> = data

    case bool do
      1 -> {:ok, true}
      0 -> {:ok, false}
      _ -> :error
    end
  end

  for i <- 1..32 do
    def decode_type(data, {:bytes, unquote(i)}, offset) do
      <<_::bytes-size(offset), bytes::bytes-size(unquote(i)), _padding::bytes-size(unquote(32 - i)), _::bytes()>> = data

      {:ok, bytes}
    end
  end

  for i <- 1..31 do
    def decode_type(data, {:int, unquote(i * 8)}, offset) do
      <<_::bytes-size(offset), _::unquote(256 - i * 8), int::signed-unquote(i * 8), _::bytes()>> = data

      {:ok, int}
    end
  end

  def decode_type(data, {:int, 256}, offset) do
    <<_::bytes-size(offset), int::signed-256, _::binary()>> = data
    {:ok, int}
  end

  for i <- 1..31 do
    def decode_type(data, {:uint, unquote(i * 8)}, offset) do
      <<_::bytes-size(offset), _::unquote(256 - i * 8), uint::unquote(i * 8), _::bytes()>> = data
      {:ok, uint}
    end
  end

  def decode_type(data, {:uint, 256}, offset) do
    <<_::bytes-size(offset), uint::256, _::binary()>> = data
    {:ok, uint}
  end

  def decode_type(data, {:tuple, inner_types}, offset) do
    <<_skipped::bytes-size(offset), inner_data::bytes()>> = data

    with {:ok, values} <- decode(inner_data, inner_types) do
      {:ok, List.to_tuple(values)}
    end
  end

  def decode_type(data, :bytes, offset) do
    <<_skipped::bytes-size(offset), len::256, bytes::bytes-size(len), _::bytes()>> = data
    {:ok, bytes}
  end

  def decode_type(data, :string, offset) do
    <<_skipped::bytes-size(offset), len::256, string::bytes-size(len), _::bytes()>> = data
    {:ok, string}
  end

  def decode_type(data, {:array, inner_type}, offset) do
    <<_skipped::bytes-size(offset), len::256, inner_data::bytes()>> = data
    decode_array(inner_data, inner_type, len)
  end

  def decode_type(data, {:array, inner_type, len}, offset) do
    <<_::bytes-size(offset), inner_data::binary()>> = data
    decode_array(inner_data, inner_type, len)
  end

  # TODO: fixed types
  def decode_type(_, type, _data) do
    throw({:unknow_type, type})
  end

  defp decode_array(data, inner_type, len) do
    if dynamic_type?(inner_type) do
      {:ok, inner_offsets} = decode(data, List.duplicate({:uint, 256}, len))

      inner_values =
        for inner_offset <- inner_offsets do
          {:ok, inner_value} = decode_type(data, inner_type, inner_offset)
          inner_value
        end

      {:ok, inner_values}
    else
      decode(data, List.duplicate(inner_type, len))
    end
  end

  def decode(data, types) do
    types
    |> Enum.reduce_while({0, []}, fn
      type, {base_offset, acc} ->
        offset =
          if dynamic_type?(type) do
            <<_::bytes-size(base_offset), dynamic_offset::256, _::binary()>> = data
            dynamic_offset
          else
            base_offset
          end

        case decode_type(data, type, offset) do
          {:ok, value} ->
            new_offset = base_offset + head_size(type)
            {:cont, {new_offset, [value | acc]}}

          :error ->
            {:halt, :error}
        end
    end)
    |> case do
      :error -> :error
      {_offset, values} -> {:ok, Enum.reverse(values)}
    end
  end
end
