defmodule Web3.ABI do
  @moduledoc """
  ABI is a module for encoding and decoding Ethereum Contract.

  Web3.ABI inspired by

    - [ABX](https://github.com/Kabie/abx)
    - [ExABI](https://github.com/poanetwork/ex_abi)

  """

  require Logger

  @doc false
  def to_hex(bytes) when is_binary(bytes), do: "0x" <> Base.encode16(bytes, case: :lower)

  @doc false
  def unhex("0x" <> hex), do: Base.decode16!(hex, case: :mixed)

  def parse_type(%{type: "tuple", components: inner_types}) do
    {:tuple, inner_types |> Enum.map(&parse_type/1)}
  end

  def parse_type(%{type: type}) do
    {:ok, [t], "", _, _, _} = Web3.ABI.TypeParser.parse(type)
    t
  end

  basic_types =
    [:address, :bool, :string, :bytes]
    |> Enum.map(&{to_string(&1), &1})

  int_types =
    for i <- 1..32 do
      {"int#{i * 8}", {:int, i * 8}}
    end

  uint_types =
    for i <- 1..32 do
      {"uint#{i * 8}", {:uint, i * 8}}
    end

  bytes_types =
    for i <- 1..32 do
      {"bytes#{i}", {:bytes, i}}
    end

  all_types = basic_types ++ int_types ++ uint_types ++ bytes_types

  for {name, type} <- all_types do
    def type_name(unquote(type)) do
      unquote(name)
    end
  end

  def type_name({:array, inner_type}) do
    type_name(inner_type) <> "[]"
  end

  def type_name({:array, inner_type, n}) do
    "#{type_name(inner_type)}[#{n}]"
  end

  def type_name({:tuple, inner_types}) do
    "(#{inner_types |> Enum.map(&type_name/1) |> Enum.join(",")})"
  end

  def type_name(type) do
    Logger.warn("Unsupported type: #{inspect(type)}")
    to_string(type)
  end
end
