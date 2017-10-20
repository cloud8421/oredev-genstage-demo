defmodule Oredev.Changes.Helper do
  def split_chunks(chunk, previous_chunk) do
    chunks = String.split(chunk, <<10>>)
    joined_chunks = previous_chunk_joined(previous_chunk, chunks)
    [complete_chunks, next_chunk] = next_chunk_split(joined_chunks)
    [without_empty_chunks(complete_chunks), next_chunk]
  end

  defp previous_chunk_joined(previous_chunk, chunks) do
    case previous_chunk do
      nil ->
        chunks

      _ ->
        [head | rest] = chunks
        [previous_chunk <> head | rest]
    end
  end

  defp next_chunk_split(chunks) do
    [init, last] = init_and_last(chunks)

    case last do
      "" -> [init, nil]
      _ -> [init, last]
    end
  end

  defp without_empty_chunks(chunks) do
    Enum.filter(chunks, fn chunk -> chunk != "" end)
  end

  defp init_and_last(chunks) do
    [head | tail] = reverse_list(chunks, [])
    [reverse_list(tail, []), head]
  end

  def reverse_list(l, acc) do
    case l do
      [] -> acc
      [h | t] -> reverse_list(t, [h | acc])
    end
  end
end
