defmodule Web3.Middleware.Pipeline do
  @moduledoc """
  Pipeline is a struct used as an argument in the callback functions of modules
  implementing the `Web3.Middleware` behaviour.

  This struct must be returned by each function to be used in the next
  middleware based on the configured middleware chain.
  """

  defstruct [
    :app_id,
    :method,
    :method_name,
    :metadata,
    :chain_id,
    :request,
    :response,
    :args,
    :return_fn,
    :json_rpc_arguments,
    assigns: %{},
    halted: false
  ]

  alias Web3.Middleware.Pipeline

  @doc """
  Puts the `key` with value equal to `value` into `assigns` map.
  """
  def assign(%Pipeline{} = pipeline, key, value) when is_atom(key) do
    %Pipeline{assigns: assigns} = pipeline

    %Pipeline{pipeline | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Puts the `key` with value equal to `value` into `metadata` map.

  Note: Use of atom keys in metadata is deprecated in favour of binary strings.
  """
  def assign_metadata(%Pipeline{} = pipeline, key, value) when is_binary(key) or is_atom(key) do
    %Pipeline{metadata: metadata} = pipeline

    %Pipeline{pipeline | metadata: Map.put(metadata, key, value)}
  end

  @doc """
  Has the pipeline been halted?
  """
  def halted?(%Pipeline{halted: halted}), do: halted

  @doc """
  Halts the pipeline by preventing further middleware downstream from being invoked.

  Prevents dispatch of the method if `halt` occurs in a `before_dispatch` callback.
  """
  def halt(%Pipeline{} = pipeline) do
    %Pipeline{pipeline | halted: true} |> respond({:error, :halted})
  end

  @doc """
  Extract the response from the pipeline
  """
  def response(%Pipeline{response: response}), do: response

  @doc """
  Sets the response to be returned to the dispatch caller, unless already set.
  """
  def respond(%Pipeline{} = pipeline, response), do: %Pipeline{pipeline | response: response}

  @doc """
  Extract the request from the pipeline
  """
  def get_request(%Pipeline{request: request}), do: request

  @doc "Set request field"
  def set_request(%Pipeline{} = pipeline, request), do: %Pipeline{pipeline | request: request}

  @doc """
  Executes the middleware chain.
  """
  def chain(pipeline, stage, middleware)
  def chain(%Pipeline{} = pipeline, _stage, []), do: pipeline
  def chain(%Pipeline{halted: true} = pipeline, :before_dispatch, _middleware), do: pipeline
  def chain(%Pipeline{halted: true} = pipeline, :after_dispatch, _middleware), do: pipeline
  def chain(%Pipeline{} = pipeline, stage, [module | modules]), do: chain(apply(module, stage, [pipeline]), stage, modules)
end
