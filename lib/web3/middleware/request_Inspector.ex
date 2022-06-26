defmodule Web3.Middleware.RequestInspector do
  @moduledoc false

  @behaviour Web3.Middleware

  require Logger

  alias Web3.Middleware.Pipeline

  def before_dispatch(%Pipeline{request: request} = pipeline) do
    Logger.info("HTTP Request Payload: #{inspect(request)}")
    pipeline
  end

  def after_dispatch(%Pipeline{} = pipeline), do: pipeline
  def after_failure(%Pipeline{} = pipeline), do: pipeline
end
