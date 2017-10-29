defmodule Oredev.Consumer.TopicSchedule do
  use GenStage

  require Logger

  def start_link(db_name) do
    GenStage.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def count_per_topic(db_name) do
    GenStage.call(via(db_name), :count_per_topic)
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

  def handle_call(:count_per_topic, _from, state) do
    total =
      state
      |> Enum.map(fn {topic, events} ->
           {topic, Enum.count(events)}
         end)
      |> Enum.into(%{})

    {:reply, total, [], state}
  end

  def handle_events(docs, _from, state) do
    Process.sleep(2000)
    Logger.info("topic_schedule #{Enum.count(docs)}")

    new_state =
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

    {:noreply, [], new_state}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end

  defp producer_via(db_name) do
    {:via, Registry, {Registry.Db, {Oredev.Producer.Changes, db_name}}}
  end
end
