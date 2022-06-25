defmodule Web3.Middleware.CustomLogger do
  @moduledoc false

  @behaviour Web3.Middleware

  require Logger

  def before_dispatch(payload) do
    Logger.info(fn -> "dispatch start" end)
    payload
  end

  def after_dispatch(payload) do
    Logger.info("after_dispatch")
    payload
  end

  def after_failure(payload) do
    Logger.info("after failure")
    payload
  end
end
