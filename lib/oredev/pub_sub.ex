defmodule Oredev.PubSub do
  def subscribe(topic) do
    Registry.register(__MODULE__, topic, [])
  end

  def publish(topic, message) do
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, {__MODULE__, topic, message})
    end)
  end
end
