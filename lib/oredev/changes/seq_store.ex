defmodule Oredev.Changes.SeqStore do
  use GenServer

  def start_link({db_name, initial_seq}) do
    GenServer.start_link(__MODULE__, initial_seq, name: via(db_name))
  end

  def set(db_name, seq) do
    GenServer.cast(via(db_name), {:set, seq})
  end

  def get(db_name) do
    GenServer.call(via(db_name), :get)
  end

  def handle_call(:get, _from, seq) do
    {:reply, seq, seq}
  end

  def handle_cast({:set, seq}, _old_seq) do
    {:noreply, seq}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end
end
