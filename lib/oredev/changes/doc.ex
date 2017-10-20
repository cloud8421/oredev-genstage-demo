defmodule Oredev.Changes.Doc do
  defstruct id: nil,
            rev: nil,
            data: %{}

  def from_map(data_map) do
    %{"_id" => id, "_rev" => rev} = data_map
    data = Map.drop(data_map, ["_id", "_rev"])

    %__MODULE__{id: id, rev: rev, data: data}
  end
end
