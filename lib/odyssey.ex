defmodule Odyssey do
  @moduledoc """
  Odyssey is a workflow engine for Elixir.
  """

  def start(_type, _args) do
    Odyssey.Supervisor.start_link()
  end
end
