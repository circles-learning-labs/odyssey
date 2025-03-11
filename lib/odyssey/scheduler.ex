defmodule Odyssey.Scheduler do
  alias Odyssey.ObanWorker

  def schedule(workflow_run, opts \\ []) do
    ObanWorker.new(%{id: workflow_run.id}, opts)
  end
end
