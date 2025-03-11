defmodule Odyssey.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    [
      {Odyssey.Repo, []},
      {Oban, Application.fetch_env!(:circles_web, Oban)}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

end
