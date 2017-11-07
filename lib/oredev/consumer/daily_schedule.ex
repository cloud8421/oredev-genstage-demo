defmodule Oredev.Consumer.DailySchedule do
  use GenStage

  require Logger

  def start_link(db_name) do
    GenStage.start_link(__MODULE__, db_name, name: via(db_name))
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
    :ok =
      GenStage.async_subscribe(
        self(),
        to: producer_via(db_name),
        min_demand: 3,
        max_demand: 5
      )

    {:consumer, db_name}
  end

  def handle_events(docs, _from, db_name) do
    Process.sleep(2000)
    Logger.info("day_schedule #{Enum.count(docs)}")

    Oredev.Store.update(__MODULE__, db_name, fn(state) ->
      Enum.reduce(docs, state, fn doc, acc ->
        day = Map.get(doc.data, "day")

        Map.update(acc, day, %{doc.id => doc}, fn current ->
          Map.put(current, doc.id, doc)
        end)
      end)
    end)

    {:noreply, [], db_name}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end

  defp producer_via(db_name) do
    {:via, Registry, {Registry.Db, {Oredev.Producer.Changes, db_name}}}
  end
end
