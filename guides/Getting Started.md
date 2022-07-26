# Getting started

Web3 can be installed from the package manager hex as follows.

1. Add `web3` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:web3, "~> 0.1.4"}]
    end
    ```
2. Fetch mix dependencies:

    ```console
    $ mix deps.get
    ```

3. Define a Application module for your app.

    ```elixir
    defmodule MyApp.Application do
      use web3, rpc_endpoint: "<PATH_TO_RPC_ENDPOINT>"
    end
    ```

4. Then you can use the following APIs

    - Infura Eth Method of the same name: [Eth API](./ETH%20API.md).
    - Includes a number of convenient utility functions: [Base API](./Base%20API.md).


    ```elixir
    iex> MyApp.Application.eth_blockNumber
    {:ok, 15034908}
    ```

