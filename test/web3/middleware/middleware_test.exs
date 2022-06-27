defmodule Web3.Middleware.MiddlewareTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  alias Web3.Middleware.Pipeline

  defmodule FirstMiddleware do
    @behaviour Web3.Middleware

    def before_dispatch(pipeline), do: pipeline
    def after_dispatch(pipeline), do: pipeline |> Pipeline.respond(2)
    def after_failure(pipeline), do: pipeline
  end

  defmodule LastMiddleware do
    @behaviour Web3.Middleware

    def before_dispatch(pipeline), do: pipeline
    def after_dispatch(pipeline), do: pipeline |> Pipeline.respond(2)
    def after_failure(pipeline), do: pipeline
  end

  defmodule Dummy do
    use Web3, rpc_endpoint: "http://localhost:8545"

    middleware FirstMiddleware
    middleware LastMiddleware
  end

  test "should call middleware for each method dispatch" do
    Web3.HTTP.Mox
    |> expect(:json_rpc, fn _url, _json, _options ->
      body = %{jsonrpc: "2.0", id: 1, result: Web3.to_hex(1)} |> Jason.encode!()

      {:ok, %{body: body, status_code: 200}}
    end)

    assert 2 = Dummy.eth_getBalance("0x0000000000000000000000000000000000000000", "latest")
  end
end
