defmodule Odyssey do
  @moduledoc """
  Odyssey is a workflow engine for Elixir.
  """

  def start(_type, _args) do
    otp_app = Application.get_env(:odyssey, :otp_app, :odyssey)
    Odyssey.Supervisor.start_link(otp_app: otp_app)
  end

  def repo do
    Application.get_env(:odyssey, :repo, Odyssey.Repo)
  end
end
