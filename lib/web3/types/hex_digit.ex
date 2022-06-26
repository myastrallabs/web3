defmodule Web3.Type.HexDigit do
  @moduledoc """
  Hex encoded integer.
  """

  use Ecto.Type

  defstruct value: 0

  @type t :: %__MODULE__{value: non_neg_integer()}

  @impl Ecto.Type
  @spec type() :: :bigint
  def type, do: :bigint

  @impl Ecto.Type
  @spec load(term()) :: {:ok, t()} | :error
  def load(term) when is_integer(term) and term >= 0, do: {:ok, %__MODULE__{value: term}}
  def load(_), do: :error

  @impl Ecto.Type
  @spec dump(t()) :: {:ok, non_neg_integer()} | :error
  def dump(%__MODULE__{value: value}) when is_integer(value) and value >= 0, do: {:ok, value}
  def dump(_), do: :error

  @impl Ecto.Type
  @spec cast(term()) :: {:ok, t()} | :error
  def cast(%__MODULE__{} = hex_digit) do
    {:ok, hex_digit}
  end

  def cast(term) when is_integer(term) and term >= 0 do
    {:ok, %__MODULE__{value: term}}
  end

  def cast(<<"0x", bytes::bytes()>>) do
    if String.match?(bytes, ~r/^[0-9a-fA-F]+$/) do
      {:ok, %__MODULE__{value: String.to_integer(bytes, 16)}}
    else
      :error
    end
  end

  def cast(term) when is_binary(term) do
    if String.match?(term, ~r/^[0-9a-fA-F]+$/) do
      {:ok, %__MODULE__{value: String.to_integer(term, 16)}}
    else
      :error
    end
  end

  def cast(_term), do: :error

  def to_string(%__MODULE__{value: value}) do
    "0x" <> String.downcase(Integer.to_string(value, 16))
  end

  defimpl String.Chars do
    def to_string(hex) do
      @for.to_string(hex)
    end
  end

  defimpl Inspect do
    def inspect(hex, _opts) do
      @for.to_string(hex)
    end
  end

  defimpl Jason.Encoder do
    alias Jason.Encode

    def encode(hex, opts) do
      hex
      |> to_string()
      |> Encode.string(opts)
    end
  end
end
