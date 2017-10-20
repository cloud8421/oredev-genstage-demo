defmodule Oredev.Consumer.DailySchedule do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ok =
      GenStage.async_subscribe(
        self(),
        to: Oredev.Producer,
        min_demand: 3,
        max_demand: 5
      )

    {:consumer, %{}}
  end

  def handle_events(docs, _from, state) do
    new_state =
      Enum.reduce(docs, state, fn doc, acc ->
        day = Map.get(doc.data, "day")

        Map.update(acc, day, %{doc.id => doc}, fn current ->
          Map.put(current, doc.id, doc)
        end)
      end)

    {:noreply, [], new_state}
  end
end
