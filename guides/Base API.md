## :construction: Base API

### Encoding and Decoding Helpers

1. Converts a hex string to a integer.

    ```elixir
    iex> Web3.to_hex(10)
    "0xA"

    iex> Web3.to_hex("0xa")
    "0xa"

    iex> Web3.to_hex(true)
    "0x1"
    ```

2. Converts a integer to hex.

    ```elixir
    iex> Web3.to_hex(10)
    "0xA"

    iex> Web3.to_hex("0xa")
    "0xa"

    iex> Web3.to_hex(true)
    "0x1"
    ```

### Address Helpers

- [ ] Web3.is_address/1
- [ ] Web3.is_checksum_address/1
  
### Currency Conversions

- [ ] Web3.to_wei/1
- [ ] Web3.from_wei/1

### Cryptographic Hashing

- [ ] Web3.keccak256/1

More details found [here](https://hexdocs.pm/web3/Web3.html)