## Middleware

As the name implies, your web3 instances can be further refined by middleware

### Built-in Middleware

- [Parser](../lib/web3/middleware/parser.ex)：Handling data from HTTP requests and response
- [Response Formatter](../lib/web3/middleware/response_formatter.ex): format http response, make return data more readable
- [Request Inspector](../lib/web3/middleware/request_inspector.ex): Output json rpc requests
- [Logger](../lib/web3/middleware/logger.ex): Detailed print request data

### Customised Middleware


```elixir
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
```
 Import the `Web3.Middleware.Pipeline` module to access convenience
  functions.

    * `assign/3` - puts a key and value into the `assigns` map
    * `halt/1` - stops execution of further middleware downstream and prevents
      dispatch of the method when used in a `before_dispatch` callback
