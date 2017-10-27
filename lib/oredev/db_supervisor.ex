defmodule Oredev.DbSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ignored, name: __MODULE__)
  end

  def start_child(db_name) do
    Supervisor.start_child(__MODULE__, [db_name])
  end

  def init(_) do
    children = [
      supervisor(Oredev.Changes.Supervisor, [])
    ]

    opts = [strategy: :simple_one_for_one]
    Supervisor.init(children, opts)
  end
end
