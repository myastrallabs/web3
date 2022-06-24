defmodule Web3Test do
  use ExUnit.Case
  doctest Web3

  test "greets the world" do
    assert Web3.hello() == :world
  end
end
