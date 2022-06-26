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

      @true_values [1, '1', true, True, 'true', 'TRUE', "1", "true", "TRUE"]
      @false_values [0, '0', false, False, 'false', 'FALSE', "0", "false", "FALSE"]

      @doc """
      Converts a integer to hex.

      ## Examples

          iex> Web3.to_hex(10)
          "0xA"

          iex> Web3.to_hex("0xa")
          "0xa"

          iex> Web3.to_hex(true)
          "0x1"

      """
      @spec to_hex(any()) :: String.t()
      def to_hex(integer) when is_integer(integer), do: "0x" <> Integer.to_string(integer, 16)
      def to_hex("0x" <> _ = hex_str), do: hex_str
      def to_hex(value) when value in @true_values, do: "0x1"
      def to_hex(value) when value in @false_values, do: "0x0"

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
      def is_address(address), do: Web3.Type.Address.validate(address)

      # @doc """
      # Takes a variety of inputs and returns its string equivalent. Text gets decoded as UTF-8.

      # ## Examples

      #   iex> Web3.to_text("0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d")

      # """
      # @spec to_text(any()) :: String.t()
      # def to_text("0x" <> value) when is_binary(value) do
      #   case Base.decode16(value) do
      #     {:ok, string} -> string
      #     :error -> :error
      #   end
      # end

      # def to_text(value) when is_integer(value), do: Integer.to_string(value)
      # def to_text(value), do: value

      @doc """
      Returns a 0x prepended 32 byte hash of the input string

      ## Examples

        iex> Web3.keccak256("123")
        "0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107"

      """
      @spec keccak256(String.t()) :: String.t()
      def keccak256(str) do
        result =
          str
          |> ExKeccak.hash_256()
          |> Base.encode16(case: :lower)

        "0x" <> result
      end

      @unit_map %{
        :noether => 0,
        :wei => 1,
        :kwei => 1_000,
        :Kwei => 1_000,
        :babbage => 1_000,
        :femtoether => 1_000,
        :mwei => 1_000_000,
        :Mwei => 1_000_000,
        :lovelace => 1_000_000,
        :picoether => 1_000_000,
        :gwei => 1_000_000_000,
        :Gwei => 1_000_000_000,
        :shannon => 1_000_000_000,
        :nanoether => 1_000_000_000,
        :nano => 1_000_000_000,
        :szabo => 1_000_000_000_000,
        :microether => 1_000_000_000_000,
        :micro => 1_000_000_000_000,
        :finney => 1_000_000_000_000_000,
        :milliether => 1_000_000_000_000_000,
        :milli => 1_000_000_000_000_000,
        :ether => 1_000_000_000_000_000_000,
        :kether => 1_000_000_000_000_000_000_000,
        :grand => 1_000_000_000_000_000_000_000,
        :mether => 1_000_000_000_000_000_000_000_000,
        :gether => 1_000_000_000_000_000_000_000_000_000,
        :tether => 1_000_000_000_000_000_000_000_000_000_000
      }

      @doc "Converts the value to whatever unit key is provided. See unit map for details."
      @spec to_wei(integer, atom) :: integer
      def to_wei(num, key) do
        if @unit_map[key] do
          num * @unit_map[key]
        else
          throw("#{key} not valid unit")
        end
      end

      @doc "Converts the value to whatever unit key is provided. See unit map for details."
      @spec from_wei(integer, atom) :: integer | float | no_return
      def from_wei(num, key) do
        if @unit_map[key] do
          num / @unit_map[key]
        else
          throw("#{key} not valid unit")
        end
      end

      @doc """
      Checks if the address is a valid checksummed address.

      ## Examples

          iex> Web3.is_checksum_address("0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d")
          true

      """
      def is_checksum_address("0x" <> original_hash), do: Web3.Type.Address.is_checksummed?(original_hash)

      # @doc """
      # Returns a checksummed address

      # ## Examples

      #     iex> Web3.to_checksum_address("c1912fEE45d61C87Cc5EA59DaE31190FFFFf232d")
      #     "0xC1912fEe45D61c87cC5EA59DAe31190FFffF232D"

      # """
      # def to_checksum_address("0x" <> address), do: Web3.Type.Address.to_checksum(address)
    end
  end
end
