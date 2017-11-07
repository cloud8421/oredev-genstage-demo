defmodule Oredev.Changes.Supervisor do
  use Supervisor

  def start_link(db_name) do
    Supervisor.start_link(__MODULE__, db_name, name: via(db_name))
  end

  def init(db_name) do
    children = [
      # GenStage Pipeline - producer
      {Oredev.Producer.Changes, db_name},
      # GenStage Pipeline - consumers and state holders
      {Oredev.Store, {Oredev.Consumer.DailySchedule, db_name}},
      {Oredev.Store, {Oredev.Consumer.TopicSchedule, db_name}},
      {Oredev.Consumer.DailySchedule, db_name},
      {Oredev.Consumer.TopicSchedule, db_name},
      {Oredev.Subscriber.DailySchedule, db_name},
      {Oredev.Subscriber.TopicSchedule, db_name},
      {Oredev.Changes.SeqStore, {{db_name, :pub_sub}, 0}},
      {Oredev.Changes.Feed, {db_name, :pub_sub}},
      {Oredev.Changes.SeqStore, {{db_name, :gen_stage}, 0}},
      {Oredev.Changes.Feed, {db_name, :gen_stage}}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  defp via(db_name) do
    {:via, Registry, {Registry.Db, {Supervisor, db_name}}}
  end

  def healthcheck(db_name) do
    components = [
      Oredev.Producer.Changes,
      Oredev.Subscriber.DailySchedule,
      Oredev.Subscriber.TopicSchedule,
      Oredev.Consumer.DailySchedule,
      Oredev.Consumer.TopicSchedule
    ]

    Enum.map(components, fn component ->
      [{pid, _}] = Registry.lookup(Registry.Db, {component, db_name})

      {component, Process.info(pid, :message_queue_len)}
    end)
  end
end
