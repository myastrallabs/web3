defmodule Web3.ABI.TypeParser do
  import NimbleParsec

  defp array_reduce(list) do
    Enum.reduce(list, &do_array_reduce/2)
  end

  defp do_array_reduce(:array, acc) do
    {:array, acc}
  end

  defp do_array_reduce(n, acc) when is_integer(n) do
    {:array, acc, n}
  end

  n3 = integer(min: 1, max: 3)
  n2 = integer(min: 1, max: 2)

  t_fix_bytes = ignore(string("bytes")) |> concat(n2) |> unwrap_and_tag(:bytes)
  t_bytes = string("bytes") |> replace(:bytes)
  t_string = string("string") |> replace(:string)
  t_function = string("function") |> replace(:function)

  t_uint = ignore(string("uint")) |> concat(n3) |> unwrap_and_tag(:uint)
  t_int = ignore(string("int")) |> concat(n3) |> unwrap_and_tag(:int)
  t_uint_syn = string("uint") |> replace({:uint, 256})
  t_int_syn = string("int") |> replace({:int, 256})

  t_address = string("address") |> replace(:address)
  t_bool = string("bool") |> replace(:bool)

  t_fixed = string("fixed") |> concat(n3) |> string("x") |> concat(n2)
  t_ufixed = string("ufixed") |> concat(n3) |> string("x") |> concat(n2)

  elementary_type =
    choice([
      t_fix_bytes,
      t_bytes,
      t_string,
      t_function,
      t_uint,
      t_int,
      t_uint_syn,
      t_int_syn,
      t_address,
      t_bool,
      t_fixed,
      t_ufixed
    ])

  postfix =
    repeat(
      choice([
        ignore(string("["))
        |> integer(min: 1)
        |> ignore(string("]")),
        string("[]") |> replace(:array)
      ])
    )

  not_tuple =
    elementary_type
    |> optional(postfix)
    |> reduce(:array_reduce)

  defparsecp(
    :tuple,
    ignore(string("("))
    |> repeat(
      choice([
        not_tuple,
        parsec(:tuple)
      ])
      |> ignore(optional(string(",")))
    )
    |> ignore(string(")"))
    |> optional(postfix)
    |> tag(:tuple)
  )

  defparsec(:parse, choice([not_tuple, parsec(:tuple)]))
end
