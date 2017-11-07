defmodule Oredev.Subscriber.DailySchedule do
  use GenServer

  require Logger

  def start_link(db_name) do
    GenServer.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def total_count(db_name) do
    Oredev.Store.get(__MODULE__, db_name)
    |> Enum.reduce(0, fn {_day, events}, count ->
      count + Enum.count(events)
    end)
  end

  def count_per_day(db_name) do
    Oredev.Store.get(__MODULE__, db_name)
    |> Enum.map(fn {day, events} ->
         {day, Enum.count(events)}
       end)
    |> Enum.into(%{})
  end

  def init(db_name) do
    Oredev.PubSub.subscribe({:change, db_name})

    {:ok, db_name}
  end

  def handle_info({Oredev.PubSub, {:change, db_name}, doc}, db_name) do
    Process.sleep(2000)
    Logger.info("subscriber day_schedule 1")

    day = Map.get(doc.data, "day")

    Oredev.Store.update(__MODULE__, db_name, fn(state) ->
      Map.update(state, day, %{doc.id => doc}, fn current ->
        Map.put(current, doc.id, doc)
      end)
    end)

    {:noreply, db_name}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end
end
