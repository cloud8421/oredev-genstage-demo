defmodule Oredev.Subscriber.DailySchedule do
  use GenServer

  require Logger

  def start_link(db_name) do
    GenServer.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def total_count(db_name) do
    GenServer.call(via(db_name), :total_count)
  end

  def count_per_day(db_name) do
    GenServer.call(via(db_name), :count_per_day)
  end

  def init(db_name) do
    Oredev.PubSub.subscribe({:change, db_name})

    {:ok, %{}}
  end

  def handle_call(:total_count, _from, state) do
    total =
      Enum.reduce(state, 0, fn {_day, events}, count ->
        count + Enum.count(events)
      end)

    {:reply, total, state}
  end

  def handle_call(:count_per_day, _from, state) do
    total =
      state
      |> Enum.map(fn {day, events} ->
           {day, Enum.count(events)}
         end)
      |> Enum.into(%{})

    {:reply, total, state}
  end

  def handle_info({Oredev.PubSub, {:change, _db_name}, doc}, state) do
    Process.sleep(2000)
    Logger.info("subscriber day_schedule 1")

    day = Map.get(doc.data, "day")

    new_state =
      Map.update(state, day, %{doc.id => doc}, fn current ->
        Map.put(current, doc.id, doc)
      end)

    {:noreply, new_state}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end
end
