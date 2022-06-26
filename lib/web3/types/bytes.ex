defmodule Web3.Type.Bytes do
  @moduledoc """
  Fixed length binary, 1 to 32 bytes.
  """

  use Ecto.Type

  defstruct [
    :bytes,
    :size
  ]

  @type t :: %__MODULE__{
          bytes: binary(),
          size: 1..32
        }

  @impl Ecto.Type
  @spec type() :: :bytea
  def type, do: :bytea

  @impl Ecto.Type
  @spec load(term()) :: {:ok, t()} | :error
  def load(<<"0x", hex_string::bytes()>>), do: cast_hex(hex_string)
  def load(<<bytes::bytes()>>), do: {:ok, %__MODULE__{bytes: bytes, size: byte_size(bytes)}}
  def load(_), do: :error

  @impl Ecto.Type
  @spec dump(t()) :: {:ok, binary()} | :error
  def dump(%__MODULE__{bytes: <<bytes::bytes()>>}), do: {:ok, bytes}
  def dump(_), do: :error

  @impl Ecto.Type
  @spec cast(term()) :: {:ok, t()} | :error
  def cast(<<"0x", hex_string::bytes()>>), do: cast_hex(hex_string)
  def cast(<<bytes::bytes()>>), do: {:ok, %__MODULE__{bytes: bytes, size: byte_size(bytes)}}
  def cast(%__MODULE__{bytes: <<_::bytes()>>, size: size} = term) when size in 1..32, do: {:ok, term}
  def cast(_term), do: :error

  defp cast_hex(hex_string) do
    case Base.decode16(hex_string, case: :mixed) do
      {:ok, bytes} ->
        {:ok, %__MODULE__{bytes: bytes, size: byte_size(bytes)}}

      _ ->
        :error
    end
  end

  def to_string(%__MODULE__{bytes: nil}) do
    "0x"
  end

  def to_string(%__MODULE__{bytes: <<bytes::bytes()>>}) do
    "0x" <> Base.encode16(bytes, case: :lower)
  end

  def to_inspect(%{size: size} = bytes) do
    "Bytes#{size}<#{__MODULE__.to_string(bytes)}>"
  end

  defimpl String.Chars do
    def to_string(bytes) do
      @for.to_string(bytes)
    end
  end

  defimpl Inspect do
    def inspect(bytes, _opts) do
      @for.to_inspect(bytes)
    end
  end

  defimpl Jason.Encoder do
    alias Jason.Encode

    def encode(bytes, opts) do
      bytes
      |> to_string()
      |> Encode.string(opts)
    end
  end
end
