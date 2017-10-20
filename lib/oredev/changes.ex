defmodule Oredev.Changes do
  use GenServer

  alias __MODULE__.Helper
  alias HTTPoison, as: H

  @options %{include_docs: true, feed: :continuous, timeout: 60_000, heartbeat: 60_000}

  defmodule State do
    defstruct database_name: nil,
              previous_chunk: nil,
              complete_chunks: []
  end

  def start_link(database_name) do
    state = %State{database_name: database_name}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    send(self(), :listen)
    {:ok, state}
  end

  def handle_info(:listen, state = %{database_name: database_name}) do
    case connect(database_name, @options) do
      {:ok, _ref} ->
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  def handle_info(reason = %H.AsyncStatus{code: code}, state = %{database_name: database_name})
      when code != 200 do
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

    decoded_chunks =
      complete_chunks
      |> Enum.map(&Poison.decode!/1)

    {
      :noreply,
      %{
        state
        | database_name: database_name,
          complete_chunks: decoded_chunks ++ state.complete_chunks,
          previous_chunk: next_chunk
      }
    }
  end

  def handle_info(%H.AsyncEnd{}, state) do
    {:stop, :stream_end, state}
  end

  def terminate(reason, state) do
    :ok
  end

  def connect(database_name, options) do
    url = Path.join([couch_base_url(), database_name, "_changes"])
    H.get(url, [], stream_to: self(), params: options, hackney: [pool: :default])
  end

  defp couch_base_url do
    "http://localhost:5984"
  end
end
