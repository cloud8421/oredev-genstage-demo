defmodule Oredev.Changes.Supervisor do
  use Supervisor

  def start_link(db_name) do
    Supervisor.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def init(db_name) do
    children = [
      {Oredev.Producer.Changes, db_name},
      {Oredev.Consumer.DailySchedule, db_name},
      {Oredev.Consumer.TopicSchedule, db_name},
      {Oredev.Changes.SeqStore, {db_name, 0}},
      {Oredev.Changes.Feed, db_name}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {Supervisor, db_name}}}
  end
end
