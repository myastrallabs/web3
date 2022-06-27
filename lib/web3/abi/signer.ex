defmodule Web3.ABI.Signer do
  @moduledoc """
  Signer is a helper class for signing transactions.

  Signer inspired by [Abx](https://github.com/Kabie/abx)
  """

  # ignore EIP-2930 for now
  @type post_1559_txn() :: %{
          chain_id: pos_integer(),
          nonce: non_neg_integer(),
          priority_fee: non_neg_integer(),
          gas_price: non_neg_integer(),
          gas_limit: non_neg_integer(),
          to: binary(),
          value: non_neg_integer(),
          data: binary()
        }

  @type legacy_post_155_txn() :: %{
          chain_id: pos_integer(),
          nonce: non_neg_integer(),
          gas_price: non_neg_integer(),
          gas_limit: non_neg_integer(),
          to: binary(),
          value: non_neg_integer(),
          data: binary()
        }

  @type legacy_pre_155_txn() :: %{
          nonce: non_neg_integer(),
          gas_price: non_neg_integer(),
          gas_limit: non_neg_integer(),
          to: binary(),
          value: non_neg_integer(),
          data: binary()
        }

  @type txn_obj :: post_1559_txn() | legacy_post_155_txn() | legacy_pre_155_txn()

  @type signed_raw_txn :: <<_::16, _::_*8>>

  @doc """
  Sign Transaction.
  """
  @spec sign_transaction(txn_obj, binary, Keyword.t()) :: signed_raw_txn()
  def sign_transaction(txn_obj, private_key, opts \\ []) do
    tco =
      txn_obj
      |> Map.merge(Map.new(opts))
      |> Map.put_new_lazy(:value, fn ->
        0
      end)
      |> Map.update(:to, <<>>, &normalize_address/1)
      |> Map.update(:data, <<>>, &normalize_data/1)

    signed_txn =
      tco
      |> do_sign_transaction(private_key)
      |> Base.encode16()

    "0x" <> signed_txn
  end

  defp do_sign_transaction(transaction, private_key) do
    case transaction do
      # Post EIP-1559, with format EIP-2718
      # TransactionType 2
      # TransactionPayload rlp([chain_id, nonce, priority_fee, gas_price, gas_limit, to, amount, data, access_list, y_parity, r, s])
      # we use empty access_list here for simplicity
      %{chain_id: chain_id, nonce: nonce, priority_fee: priority_fee, gas_price: gas_price, gas_limit: gas_limit, to: to, value: value, data: data} ->
        msg_to_sign = <<0x02>> <> ExRLP.encode([chain_id, nonce, priority_fee, gas_price, gas_limit, to, value, data, []])
        {r, s, v} = make_signature(msg_to_sign, private_key)
        y_parity = v - 27

        <<0x02>> <> ExRLP.encode([chain_id, nonce, priority_fee, gas_price, gas_limit, to, value, data, [], y_parity, r, s])

      # LegacyTransaction, post EIP-155
      # rlp([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
      %{chain_id: chain_id, nonce: nonce, gas_price: gas_price, gas_limit: gas_limit, to: to, value: value, data: data} ->
        msg_to_sign = ExRLP.encode([nonce, gas_price, gas_limit, to, value, data, chain_id, 0, 0])
        {r, s, v} = make_signature(msg_to_sign, private_key)
        y_parity = v - 27
        v = chain_id * 2 + 35 + y_parity
        ExRLP.encode([nonce, gas_price, gas_limit, to, value, data, v, r, s])

      # LegacyTransaction, pre EIP-155
      %{nonce: nonce, gas_price: gas_price, gas_limit: gas_limit, to: to, value: value, data: data} ->
        msg_to_sign = ExRLP.encode([nonce, gas_price, gas_limit, to, value, data])
        {r, s, v} = make_signature(msg_to_sign, private_key)
        y_parity = v - 27
        v = y_parity + 27
        ExRLP.encode([nonce, gas_price, gas_limit, to, value, data, v, r, s])
    end
  end

  defp normalize_address(address) do
    case Web3.Type.Address.cast(address) do
      {:ok, address} -> address.bytes
      _ -> <<>>
    end
  end

  defp normalize_data(data) do
    case data do
      "0x" <> hex -> Base.decode16!(hex, case: :mixed)
      binary when is_binary(binary) -> binary
      _ -> <<>>
    end
  end

  defp make_signature(msg_to_sign, private_key) do
    <<v, r::256, s::256>> =
      msg_to_sign
      |> ExKeccak.hash_256()
      |> Curvy.sign(private_key, compact: true, compressed: false, hash: false)

    {r, s, v}
  end
end
