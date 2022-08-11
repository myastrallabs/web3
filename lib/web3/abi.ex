defmodule Web3.ABI do
  @moduledoc """
  ABI is a module for encoding and decoding Ethereum Contract.

  Web3.ABI inspired by

    - [ABX](https://github.com/Kabie/abx)

  """

  require Logger

  alias Web3.ABI

  @type types() :: ABX.Types.types()

  @doc "encode"
  defdelegate encode(values, types), to: ABI.TypeEncoder
  @doc "decode"
  defdelegate decode(values, types), to: ABI.TypeDecoder

  defmacro sigil_A({:<<>>, _, [addr_str]}, _mods) do
    {:ok, address} = Web3.Type.Address.cast(addr_str)
    Macro.escape(address)
  end

  def to_hex(bytes) when is_binary(bytes), do: "0x" <> Base.encode16(bytes, case: :lower)

  def unhex("0x" <> hex), do: Base.decode16!(hex, case: :mixed)
end
