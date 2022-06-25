defmodule Web3.Dispatcher do
  @moduledoc false

  require Logger

  alias Web3

  alias Web3.Middleware.Pipeline

  defmodule Payload do
    @moduledoc false

    defstruct [
      :app_id,
      :chain_id,
      :method_name,
      :args,
      :return_fn,
      :method,
      :metadata,
      :returning,
      :json_rpc_args,
      middleware: []
    ]
  end

  def dispatch(%Payload{method: _method} = payload) do
    pipeline = to_pipeline(payload)

    pipeline = before_dispatch(pipeline, payload)

    IO.inspect(pipeline, label: "pipeline")

    unless Pipeline.halted?(pipeline) do
      pipeline
      |> execute(payload)
      |> Pipeline.response()
    else
      pipeline
      |> after_failure(payload)
      |> Pipeline.response()
    end
  end

  defp execute(%Pipeline{} = pipeline, %Payload{} = payload) do
    %{request: request, json_rpc_args: json_rpc_args} = pipeline

    result = Web3.json_rpc(request, json_rpc_args)

    IO.inspect(result, label: "result")

    # FIXME [] retry is here
    case result do
      {:ok, response} ->
        pipeline
        |> Pipeline.respond({:ok, response})
        |> after_dispatch(payload)

      {:error, error} ->
        pipeline
        |> Pipeline.respond({:error, error})
        |> after_failure(payload)

      {:error, error, reason} ->
        pipeline
        |> Pipeline.assign(:error_reason, reason)
        |> Pipeline.respond({:error, error})
        |> after_failure(payload)
    end
  end

  defp to_pipeline(%Payload{} = payload) do
    struct(Pipeline, Map.from_struct(payload))
  end

  defp before_dispatch(%Pipeline{} = pipeline, %Payload{middleware: middleware}) do
    Pipeline.chain(pipeline, :before_dispatch, middleware)
  end

  defp after_dispatch(%Pipeline{} = pipeline, %Payload{middleware: middleware}) do
    Pipeline.chain(pipeline, :after_dispatch, middleware)
  end

  defp after_failure(%Pipeline{response: {:error, error}} = pipeline, %Payload{} = payload) do
    %Payload{middleware: middleware} = payload

    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.chain(:after_failure, middleware)
  end

  defp after_failure(
         %Pipeline{response: {:error, error, reason}} = pipeline,
         %Payload{} = payload
       ) do
    %Payload{middleware: middleware} = payload

    pipeline
    |> Pipeline.assign(:error, error)
    |> Pipeline.assign(:error_reason, reason)
    |> Pipeline.chain(:after_failure, middleware)
  end

  defp after_failure(%Pipeline{} = pipeline, %Payload{} = payload) do
    %Payload{middleware: middleware} = payload

    Pipeline.chain(pipeline, :after_failure, middleware)
  end
end
