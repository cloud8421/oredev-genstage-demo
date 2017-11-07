defmodule Oredev.Consumer.TopicSchedule do
  use GenStage

  require Logger

  def start_link(db_name) do
    GenStage.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def count_per_topic(db_name) do
    Oredev.Store.get(__MODULE__, db_name)
    |> Enum.map(fn {topic, events} ->
         {topic, Enum.count(events)}
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
    Logger.info("topic_schedule #{Enum.count(docs)}")

    Oredev.Store.update(__MODULE__, db_name, fn(state) ->
      Enum.reduce(docs, state, fn doc, acc ->
        topics = Map.get(doc.data, "topics")

        new_data =
          topics
          |> Enum.map(fn t -> {t, [doc]} end)
          |> Enum.into(%{})

        Map.merge(acc, new_data, fn _k, v1, v2 ->
          v1 ++ v2
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
