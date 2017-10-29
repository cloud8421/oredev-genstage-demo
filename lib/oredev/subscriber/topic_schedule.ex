defmodule Oredev.Subscriber.TopicSchedule do
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

  def handle_call(:count_per_topic, _from, state) do
    total =
      state
      |> Enum.map(fn {topic, events} ->
           {topic, Enum.count(events)}
         end)
      |> Enum.into(%{})

    {:reply, total, state}
  end

  def handle_info({Oredev.PubSub, {:change, _db_name}, doc}, state) do
    Process.sleep(2000)
    Logger.info("subscriber topic_schedule 1")

    topics = Map.get(doc.data, "topics")

    new_data =
      topics
      |> Enum.map(fn t -> {t, [doc]} end)
      |> Enum.into(%{})

    new_state =
      Map.merge(state, new_data, fn _k, v1, v2 ->
        v1 ++ v2
      end)

    {:noreply, new_state}
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name}}}
  end
end
