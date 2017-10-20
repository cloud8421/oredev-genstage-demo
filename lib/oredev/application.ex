defmodule Oredev.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Oredev.Producer, :ok},
      {Oredev.Changes.SeqStore, 0},
      {Oredev.Changes, "oredev"}
      # Starts a worker by calling: Oredev.Worker.start_link(arg)
      # {Oredev.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Oredev.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
