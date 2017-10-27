defmodule Oredev.Consumer.DailySchedule do
  use GenStage

  require Logger

  def start_link(db_name) do
    GenStage.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def total_count(db_name) do
    GenStage.call(via(db_name), :total_count)
  end

  def count_per_day(db_name) do
    GenStage.call(via(db_name), :count_per_day)
  end

  def init(db_name) do
    :ok =
      GenStage.async_subscribe(
        self(),
        to: producer_via(db_name),
        min_demand: 3,
        max_demand: 5
      )

    {:consumer, %{}}
  end

  def handle_call(:total_count, _from, state) do
    total =
      Enum.reduce(state, 0, fn {_day, events}, count ->
        count + Enum.count(events)
      end)

    {:reply, total, [], state}
  end

  def handle_call(:count_per_day, _from, state) do
    total =
      state
      |> Enum.map(fn {day, events} ->
           {day, Enum.count(events)}
         end)
      |> Enum.into(%{})

    {:reply, total, [], state}
  end

  def handle_events(docs, _from, state) do
    Process.sleep(2000)
    Logger.info("day_schedule #{Enum.count(docs)}")

    new_state =
      Enum.reduce(docs, state, fn doc, acc ->
        day = Map.get(doc.data, "day")

        Map.update(acc, day, %{doc.id => doc}, fn current ->
          Map.put(current, doc.id, doc)
        end)
      end)

    {:noreply, [], new_state}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end

  defp producer_via(db_name) do
    {:via, Registry, {Registry.Db, {Oredev.Producer.Changes, db_name}}}
  end
end
