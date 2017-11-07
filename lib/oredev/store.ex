defmodule Oredev.Store do
  def start_link({module, db_name}) do
    Agent.start_link(fn() -> %{} end, name: via(module, db_name))
  end

  def child_spec({module, db_name}) do
    %{
      id: {__MODULE__, module, db_name},
      start: {__MODULE__, :start_link, [{module, db_name}]}
    }
  end

  def update(module, db_name, update_fn) do
    Agent.update(via(module, db_name), update_fn)
  end

  def get(module, db_name) do
    Agent.get(via(module, db_name), fn(current) -> current end)
  end

  defp via(module, db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, module, db_name}}}
  end
end
