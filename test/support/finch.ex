defmodule Web3.Support.Finch do
  @moduledoc """
  Uses `Finch` for `Web3.HTTP`
  """

  alias Web3.HTTP

  @behaviour HTTP

  @impl HTTP
  def json_rpc(_url, _json, _options), do: {:ok, %{}}
end
