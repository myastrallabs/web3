defmodule Web3.Utils do
  @moduledoc false

  defmacro __using__(_tops) do
    quote do
      @doc """
      Converts a hex string to a integer.

      ## Examples

          iex> Web3.to_integer(10)
          10

          iex> Web3.to_integer("0xa")
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

          iex> Web3.to_hex(10)
          "0xA"

          iex> Web3.to_hex("0xa")
          "0xa"

      """
      @spec to_hex(non_neg_integer() | String.t()) :: String.t()
      def to_hex(integer) when is_integer(integer), do: "0x" <> Integer.to_string(integer, 16)
      def to_hex("0x" <> _ = hex_str), do: hex_str

      @doc """
      Validates a hexadecimal encoded string to see if it conforms to an address.

      ## Examples

        iex> Web3.is_address("0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d")
        {:ok, "0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d"}

        iex> Web3.is_address("0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232H")
        {:error, :invalid_characters}

      """
      @spec is_address(String.t()) ::
              {:ok, String.t()}
              | {:error, :invalid_length | :invalid_characters | :invalid_checksum}
      def is_address(address), do: Web3.Type.Hash.Address.validate(address)
    end
  end
end
