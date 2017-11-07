defmodule Oredev.Subscriber.TopicSchedule do
  use GenServer

  require Logger

  def start_link(db_name) do
    GenServer.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def count_per_topic(db_name) do
    Oredev.Store.get(__MODULE__, db_name)
    |> Enum.map(fn {topic, events} ->
         {topic, Enum.count(events)}
       end)
    |> Enum.into(%{})
  end

  def init(db_name) do
    Oredev.PubSub.subscribe({:change, db_name})

    {:ok, db_name}
  end

  def handle_info({Oredev.PubSub, {:change, db_name}, doc}, db_name) do
    Process.sleep(2000)
    Logger.info("subscriber topic_schedule 1")

    topics = Map.get(doc.data, "topics")

    new_data =
      topics
      |> Enum.map(fn t -> {t, [doc]} end)
      |> Enum.into(%{})

    Oredev.Store.update(__MODULE__, db_name, fn(state) ->
      Map.merge(state, new_data, fn _k, v1, v2 ->
        v1 ++ v2
      end)
    end)

    {:noreply, db_name}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end
end
