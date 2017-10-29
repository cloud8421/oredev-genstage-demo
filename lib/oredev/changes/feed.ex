defmodule Oredev.Changes.Feed do
  use GenServer

  alias Oredev.Producer
  alias Oredev.Changes.{Doc, Helper, SeqStore}

  require Logger

  @options %{include_docs: true, feed: :continuous, timeout: 60_000, heartbeat: 60_000}

  defmodule State do
    defstruct mode: :pub_sub,
              database_name: nil,
              previous_chunk: nil
  end

  def start_link({database_name, mode}) when mode in [:pub_sub, :gen_stage] do
    state = %State{database_name: database_name, mode: mode}
    GenServer.start_link(__MODULE__, state, name: via(database_name, mode))
  end

  def child_spec({db_name, mode}) do
    %{
      id: {Oredev.Changes.Feed, db_name, mode},
      start: {Oredev.Changes.Feed, :start_link, [{db_name, mode}]}
    }
  end

  def init(state) do
    send(self(), :listen)
    {:ok, state}
  end

  def handle_info(:listen, state = %{database_name: database_name, mode: mode}) do
    options = Map.put(@options, :since, SeqStore.get({database_name, mode}))

    case connect(database_name, options) do
      {:ok, ref} ->
        :hackney.stream_next(ref)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  def handle_info({:hackney_response, _ref, {:status, code, reason}}, state) when code != 200 do
    {:stop, reason, state}
  end

  def handle_info({:hackney_response, ref, {:status, _code, _reason}}, state) do
    :hackney.stream_next(ref)
    {:noreply, state}
  end

  def handle_info({:hackney_response, ref, {:headers, _headers}}, state) do
    :hackney.stream_next(ref)
    {:noreply, state}
  end

  def handle_info({:hackney_response, _ref, :done}, state) do
    {:stop, :stream_end, state}
  end

  def handle_info({:hackney_response, _ref, {:error, {:closed, :timeout}}}, state) do
    {:stop, :stream_end, state}
  end

  def handle_info(
        {:hackney_response, ref, chunk},
        state = %{database_name: database_name, mode: mode, previous_chunk: previous_chunk}
      ) do
    [complete_chunks, next_chunk] = Helper.split_chunks(chunk, previous_chunk)

    changes =
      complete_chunks
      |> Enum.map(&Poison.decode!/1)

    process!(database_name, mode, changes)

    :hackney.stream_next(ref)

    {
      :noreply,
      %{
        state
        | database_name: database_name,
          previous_chunk: next_chunk
      }
    }
  end

  def handle_info(_error, state) do
    Logger.warn("reconnecting...")
    {:stop, :normal, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp connect(database_name, options) do
    url = Path.join([couch_base_url(), database_name, "_changes"])
    qs = URI.encode_query(options)
    url_with_qs = url <> "?" <> qs
    opts = [async: :once, stream_to: self(), params: options, hackney: [pool: :default]]
    :hackney.get(url_with_qs, [], "", opts)
  end

  defp process!(database_name, mode, changes) do
    Enum.each(changes, fn change ->
      last_seq = Map.get(change, "seq")

      doc =
        change
        |> Map.get("doc")
        |> Doc.from_map()

      case mode do
        :pub_sub -> Oredev.PubSub.publish({:change, database_name}, doc)
        :gen_stage -> Producer.Changes.ingest(database_name, doc)
      end

      Logger.info("feed mode=#{mode} #{last_seq}")
      SeqStore.set({database_name, mode}, last_seq)
    end)
  end

  defp couch_base_url do
    "http://localhost:5984"
  end

  defp via(db_name, mode) do
    {:via, Registry, {Registry.Db, {__MODULE__, db_name, mode}}}
  end
end
