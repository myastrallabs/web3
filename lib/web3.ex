defmodule Web3 do
  @moduledoc false
  use Web3.Utils

  alias Web3.HTTP

  def json_rpc(payload, json_rpc_arguments), do: HTTP.json_rpc(payload, json_rpc_arguments)
end
