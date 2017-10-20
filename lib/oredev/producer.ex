defmodule Oredev.Producer do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def ingest(doc) do
    GenStage.call(__MODULE__, {:ingest, doc})
  end

  def init(:ok) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_call({:ingest, doc}, from, {queue, demand}) do
    dispatch_docs(:queue.in({from, doc}, queue), demand, [])
  end

  def handle_demand(incoming_demand, {queue, demand}) do
    dispatch_docs(queue, incoming_demand + demand, [])
  end

  defp dispatch_docs(queue, demand, docs) do
    with d when d > 0 <- demand,
         {item, queue} = :queue.out(queue),
         {:value, {from, doc}} <- item do
      GenStage.reply(from, :ok)
      dispatch_docs(queue, demand - 1, [doc | docs])
    else
      _ -> {:noreply, Enum.reverse(docs), {queue, demand}}
    end
  end
end
