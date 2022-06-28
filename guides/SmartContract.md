## SmartContract

### Method SmartContrat

```elixir
defmodule MyApp.Application do
  use Web3, rpc_endpoint: "<RPC_ENDPOINT_PATH>"
  
  @abi [
    %{
      inputs: [
        %{
          internalType: "address",
          name: "owner",
          type: "address"
        }
      ],
      name: "balanceOf",
      outputs: [
        %{
          internalType: "uint256",
          name: "",
          type: "uint256"
        }
      ],
      stateMutability: "view",
      type: "function"
    },
    %{
      constant: false,
      inputs: [
        %{
          internalType: "address",
          name: "spender",
          type: "address"
        },
        %{
          internalType: "uint256",
          name: "amount",
          type: "uint256"
        }
      ],
      name: "approve",
      outputs: [
        %{
          internalType: "bool",
          name: "",
          type: "bool"
        }
      ],
      payable: false,
      stateMutability: "nonpayable",
      type: "function"
    }
  ]
  
  def query_balance_from_contract do
     requests = [
      %{
      	args: ["0xF4986360a6d873ea02F79eC3913be6845e0308A4"],
      	contract_address: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      	from: nil,
      	method_name: :balanceOf
    	 }
     ]
     Web3.execute_contract(requests, @abi)
  end
end
```


### Compiled SmartContract

```elixir
defmodule MyApp.Application do
  use Web3, rpc_endpoint: "<RPC_ENDPOINT_PATH>"
  
  # macro
  contract :FirstContract, contract_address: "", abi_path: "<PATH_TO_ABI_JSON_FILE>"
end

iex> MyApp.Application.balanceOf_address_("0xF4986360a6d873ea02F79eC3913be6845e0308A4")
{:ok, 0}
```