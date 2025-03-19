defmodule Odyssey.Supervisor do
  @moduledoc """
  The supervisor for the Odyssey application.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    [
      {Oban, Application.fetch_env!(opts[:otp_app], Oban)}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
