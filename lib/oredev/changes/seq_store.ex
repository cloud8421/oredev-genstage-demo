defmodule Oredev.Changes.SeqStore do
  use GenServer

  def start_link(initial_seq) do
    GenServer.start_link(__MODULE__, initial_seq, name: __MODULE__)
  end

  def set(seq) do
    GenServer.cast(__MODULE__, {:set, seq})
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call(:get, _from, seq) do
    {:reply, seq, seq}
  end

  def handle_cast({:set, seq}, _old_seq) do
    {:noreply, seq}
  end
end
