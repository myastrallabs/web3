defmodule Web3.Config.Store do
  @moduledoc false

  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Get the configuration all running instances.
  """
  def all do
    :ets.tab2list(__MODULE__)
    |> Enum.map(fn {module_name, config} -> {module_name, config} end)
  end

  @doc """
  Save the configuration for a specific instance.
  """
  def save(module_name, config) do
    GenServer.call(__MODULE__, {:save, module_name, config})
  end

  @doc """
  Get the module configuration.
  """
  def get(module_name) when is_atom(module_name), do: lookup(module_name)

  @doc """
  Get the value of the config setting for the given module
  """
  def get(name, setting) when is_atom(name) and is_atom(setting), do: lookup(name) |> Keyword.get(setting)

  @impl GenServer
  def init(_init_arg) do
    table = :ets.new(__MODULE__, [:named_table, read_concurrency: true])

    {:ok, table}
  end

  @impl GenServer
  def handle_call({:save, module_name, config}, _from, table) do
    true = :ets.insert(table, {module_name, config})

    {:reply, :ok, table}
  end

  defp lookup(name) do
    :ets.lookup(__MODULE__, name)
  rescue
    ArgumentError ->
      raise "could not lookup #{inspect(name)} because it was not started or it does not exist"
  end
end
