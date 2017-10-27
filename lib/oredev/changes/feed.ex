defmodule Oredev.Changes.Feed do
  use GenServer

  alias Oredev.Producer
  alias Oredev.Changes.{Doc, Helper, SeqStore}
  alias HTTPoison, as: H

  @options %{include_docs: true, feed: :continuous, timeout: 60_000, heartbeat: 60_000}

  defmodule State do
    defstruct database_name: nil,
              previous_chunk: nil
  end

  def start_link(database_name) do
    state = %State{database_name: database_name}
    GenServer.start_link(__MODULE__, state, name: via(database_name))
  end

  def init(state) do
    send(self(), :listen)
    {:ok, state}
  end

  def handle_info(:listen, state = %{database_name: database_name}) do
    options = Map.put(@options, :since, SeqStore.get(database_name))

    case connect(database_name, options) do
      {:ok, _ref} ->
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  def handle_info(reason = %H.AsyncStatus{code: code}, state) when code != 200 do
    {:stop, reason, state}
  end

  def handle_info(%H.AsyncStatus{}, state) do
    {:noreply, state}
  end

  def handle_info(%H.AsyncHeaders{}, state) do
    {:noreply, state}
  end

  def handle_info(
        %H.AsyncChunk{chunk: chunk},
        state = %{database_name: database_name, previous_chunk: previous_chunk}
      ) do
    [complete_chunks, next_chunk] = Helper.split_chunks(chunk, previous_chunk)

    changes =
      complete_chunks
      |> Enum.map(&Poison.decode!/1)

    process!(database_name, changes)

    {
      :noreply,
      %{
        state
        | database_name: database_name,
          previous_chunk: next_chunk
      }
    }
  end

  def handle_info(%H.AsyncEnd{}, state) do
    {:stop, :stream_end, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp connect(database_name, options) do
    url = Path.join([couch_base_url(), database_name, "_changes"])
    H.get(url, [], stream_to: self(), params: options, hackney: [pool: :default])
  end

  defp process!(database_name, changes) do
    Enum.each(changes, fn change ->
      last_seq = Map.get(change, "seq")

      doc = change
            |> Map.get("doc")
            |> Doc.from_map()

      Producer.ingest(database_name, doc)
      SeqStore.set(database_name, last_seq)
    end)
  end

  defp couch_base_url do
    "http://localhost:5984"
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {Feed, db_name}}}
  end
end
