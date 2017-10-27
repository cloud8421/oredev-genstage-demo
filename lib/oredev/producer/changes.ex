defmodule Oredev.Producer.Changes do
  use GenStage

  def start_link(db_name) do
    GenStage.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def ingest(db_name, doc) do
    GenStage.call(via(db_name), {:ingest, doc})
  end

  def init(_db_name) do
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

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {Producer.Changes, db_name}}}
  end
end
