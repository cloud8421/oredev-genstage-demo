defmodule Oredev.Changes.SeqStore do
  use GenServer

  def start_link({ref, initial_seq}) do
    GenServer.start_link(__MODULE__, initial_seq, name: via(ref))
  end

  def init(initial_seq) do
    {:ok, initial_seq}
  end

  def child_spec({ref, initial_seq}) do
    %{
      id: {Oredev.Changes.SeqStore, ref},
      start: {Oredev.Changes.SeqStore, :start_link, [{ref, initial_seq}]}
    }
  end

  def set(ref, seq) do
    GenServer.cast(via(ref), {:set, seq})
  end

  def get(ref) do
    GenServer.call(via(ref), :get)
  end

  def handle_call(:get, _from, seq) do
    {:reply, seq, seq}
  end

  def handle_cast({:set, seq}, _old_seq) do
    {:noreply, seq}
  end

  defp via(ref) do
    {:via, Registry, {Registry.Db, {__MODULE__, ref}}}
  end
end
