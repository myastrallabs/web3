defmodule Web3.Middleware.Logger do
  @moduledoc false

  @behaviour Web3.Middleware

  require Logger

  alias Web3.Middleware.Pipeline
  import Pipeline

  def before_dispatch(%Pipeline{} = pipeline) do
    Logger.info(fn -> "Dispatch start #{inspect(pipeline)}" end)

    assign(pipeline, :started_at, DateTime.utc_now())
  end

  def after_dispatch(%Pipeline{} = pipeline) do
    Logger.info(fn ->
      "Dispatch succeeded in #{inspect(pipeline)} #{formatted_diff(delta(pipeline))}"
    end)

    pipeline
  end

  def after_failure(%Pipeline{assigns: %{error: error, error_reason: error_reason}} = pipeline) do
    Logger.error(fn ->
      "Failed #{inspect(error)} in #{formatted_diff(delta(pipeline))}, due to: #{inspect(error_reason)}"
    end)

    pipeline
  end

  def after_failure(%Pipeline{assigns: %{error: error}} = pipeline) do
    Logger.error(fn ->
      "Failed #{inspect(error)} in #{formatted_diff(delta(pipeline))}"
    end)

    pipeline
  end

  def after_failure(%Pipeline{} = pipeline), do: pipeline

  defp delta(%Pipeline{assigns: %{started_at: started_at}}) do
    DateTime.diff(DateTime.utc_now(), started_at, :microsecond)
  end

  defp formatted_diff(diff) when diff > 1_000_000,
    do: [diff |> div(1_000_000) |> Integer.to_string(), "s"]

  defp formatted_diff(diff) when diff > 1_000,
    do: [diff |> div(1_000) |> Integer.to_string(), "ms"]

  defp formatted_diff(diff), do: [diff |> Integer.to_string(), "µs"]
end
