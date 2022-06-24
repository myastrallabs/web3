defmodule Web3.Utils do
  @moduledoc false

  @doc """
  Converts a hex string to a integer.

  ## Examples

      iex> Web3.Utils.to_integer(10)
      10

      iex> Web3.Utils.to_integer("0xa")
      10

  """
  @spec to_integer(String.t() | non_neg_integer()) :: non_neg_integer() | :error
  def to_integer("0x" <> hexadecimal_digits) do
    String.to_integer(hexadecimal_digits, 16)
  end

  def to_integer(integer) when is_integer(integer), do: integer

  def to_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      {integer, ""} -> integer
      _ -> :error
    end
  end

  @doc """
  Converts a integer to hex.

  ## Examples

      iex> Web3.Utils.to_hex(10)
      "0xA"

      iex> Web3.Utils.to_hex("0xa")
      "0xa"

  """
  @spec to_hex(non_neg_integer() | String.t()) :: String.t()
  def to_hex(integer) when is_integer(integer), do: "0x" <> Integer.to_string(integer, 16)
  def to_hex("0x" <> _ = hex_str), do: hex_str
end
