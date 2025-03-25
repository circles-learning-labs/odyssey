defmodule Odyssey do
  @moduledoc """
  Odyssey is a workflow engine for Elixir.
  """

  def start_link(opts) do
    Supervisor.start_link(Odyssey.Supervisor, opts, name: __MODULE__)
  end

  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    otp_app = Application.get_env(:odyssey, :otp_app, :odyssey)

    opts
    |> Keyword.put(:otp_app, otp_app)
    |> Odyssey.Supervisor.child_spec()
  end

  def repo do
    Application.get_env(:odyssey, :repo, Odyssey.Repo)
  end
end
