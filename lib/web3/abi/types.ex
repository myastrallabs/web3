defmodule Web3.ABI.Types do
  @moduledoc false

  require Logger

  def dynamic_type?(:string), do: true
  def dynamic_type?(:bytes), do: true
  def dynamic_type?({:array, _}), do: true
  def dynamic_type?({:array, type, _}), do: dynamic_type?(type)
  def dynamic_type?({:tuple, inner_types}), do: Enum.any?(inner_types, &dynamic_type?/1)
  def dynamic_type?(_type), do: false

  def head_size({:tuple, inner_types}) do
    if Enum.any?(inner_types, &dynamic_type?/1) do
      32
    else
      inner_types
      |> Enum.map(&head_size/1)
      |> Enum.sum()
    end
  end

  def head_size({:array, inner_type, n}) do
    if dynamic_type?(inner_type) do
      32
    else
      head_size(inner_type) * n
    end
  end

  def head_size(_), do: 32

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

  def parse(%{type: "tuple", components: inner_types}) do
    {:tuple, inner_types |> Enum.map(&parse/1)}
  end

  def parse(%{type: type}) do
    {:ok, [t], "", _, _, _} = Web3.ABI.TypeParser.parse(type)
    t
  end

  for {name, type} <- all_types do
    def name(unquote(type)) do
      unquote(name)
    end
  end

  def name({:array, inner_type}) do
    name(inner_type) <> "[]"
  end

  def name({:array, inner_type, n}) do
    "#{name(inner_type)}[#{n}]"
  end

  def name({:tuple, inner_types}) do
    "(#{inner_types |> Enum.map(&name/1) |> Enum.join(",")})"
  end

  def name(type) do
    Logger.warn("Unsupported type: #{inspect(type)}")
    to_string(type)
  end
end
