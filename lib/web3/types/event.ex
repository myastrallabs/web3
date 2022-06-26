defmodule Web3.Type.Event do
  @moduledoc false

  defstruct [
    :name,
    :anonymous,
    :inputs,
    :signature
  ]

  defmacro __using__(opts) do
    event = opts[:event]

    input_names = event.inputs |> Enum.map(&elem(&1, 0))
    event_module = Module.concat(__CALLER__.module, event.name)

    quote do
      defmodule unquote(event_module) do
        @moduledoc """
        #{unquote(to_definition(event))}

            #{unquote(event.signature)}
        """

        defstruct unquote(input_names)

        def abi() do
          unquote(Macro.escape(event))
        end
      end

      @events {unquote(event.signature), unquote(event_module)}
    end
  end

  @spec decode_log(atom(), %{data: binary(), topics: [String.t()]}) :: map()
  def decode_log(event_module, %{data: data, topics: [signature | topics]}) do
    %__MODULE__{signature: ^signature, inputs: inputs} = event_module.abi()

    {indexed_inputs, data_inputs} =
      inputs
      |> Enum.split_with(&elem(&1, 2)[:indexed])

    indexed_field_types =
      indexed_inputs
      |> Enum.map(&elem(&1, 1))

    data_field_types =
      data_inputs
      |> Enum.map(&elem(&1, 1))

    indexed_fields =
      topics
      |> Enum.map(&Web3.ABI.unhex/1)
      |> Enum.zip(indexed_field_types)
      |> Enum.map(fn {bytes, type} ->
        {:ok, value, _} = Web3.ABI.TypeDecoder.decode_type(bytes, type, 0)
        value
      end)

    {:ok, data_fields} = Web3.ABI.TypeDecoder.decode_data(data, data_field_types)

    fields = build_event([], inputs, data_fields, indexed_fields)
    struct!(event_module, fields)
  end

  def build_event(fields, [], _data, _indexed), do: fields

  def build_event(fields, [{name, _type, meta} | inputs], data, indexed) do
    if meta[:indexed] do
      build_event([{name, hd(indexed)} | fields], inputs, data, tl(indexed))
    else
      build_event([{name, hd(data)} | fields], inputs, tl(data), indexed)
    end
  end

  def to_definition(%__MODULE__{name: name, inputs: inputs, anonymous: anonymous}) do
    param_types =
      inputs
      |> Enum.map(fn
        {name, type, meta} ->
          type = Web3.ABI.type_name(type)

          if meta[:indexed] do
            "#{type} indexed #{name}"
          else
            "#{type} #{name}"
          end
      end)
      |> Enum.join(", ")

    if anonymous do
      "#{name}(#{param_types}) anonymous"
    else
      "#{name}(#{param_types})"
    end
  end
end
