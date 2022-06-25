defmodule Web3.Middleware do
  @moduledoc """
  Middleware provides an extension point to add functions that you want to be
  called for every method JSON RPC API.

  Implement the `Web3.Middleware` behaviour in your module and define the
  `c:before_dispatch/1`, `c:after_dispatch/1`, and `c:after_failure/1` callback
  functions.

  Middleware inspired by

    - [Commanded](https://github.com/commanded/commanded)
    - [Absinthe](https://github.com/absinthe-graphql/absinthe)

  ## Example middleware

      defmodule NoOpMiddleware do
        @behaviour Web3.Middleware

        alias Web3.Middleware.Pipeline
        import Pipeline

        def before_dispatch(%Pipeline{method: method} = pipeline) do
          pipeline
        end

        def after_dispatch(%Pipeline{method: method} = pipeline) do
          pipeline
        end

        def after_failure(%Pipeline{method: method} = pipeline) do
          pipeline
        end
      end

  Import the `Web3.Middleware.Pipeline` module to access convenience
  functions.

    * `assign/3` - puts a key and value into the `assigns` map
    * `halt/1` - stops execution of further middleware downstream and prevents
      dispatch of the method when used in a `before_dispatch` callback

  """

  alias Web3.Middleware.Pipeline

  @type pipeline :: %Pipeline{}

  @callback before_dispatch(pipeline) :: pipeline
  @callback after_dispatch(pipeline) :: pipeline
  @callback after_failure(pipeline) :: pipeline
end
