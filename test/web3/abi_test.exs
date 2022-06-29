defmodule Web3.ABITest do
  @moduledoc false

  use ExUnit.Case
  doctest Web3.ABI

  test "parse abi types" do
    types = [
      {
        "bytes3[2]",
        {:array, {:bytes, 3}, 2}
      },
      {
        "bytes4[][]",
        {:array, {:array, {:bytes, 4}}}
      },
      {
        "uint[][]",
        {:array, {:array, {:uint, 256}}}
      },
      {
        "(string,bytes,uint32)",
        {:tuple, [:string, :bytes, {:uint, 32}]}
      },
      {
        "(())",
        {:tuple, [tuple: []]}
      }
    ]

    for {text, parsed} <- types do
      assert Web3.ABI.parse_type(%{type: text}) == parsed
    end
  end
end
