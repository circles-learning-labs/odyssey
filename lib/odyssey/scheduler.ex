defmodule Odyssey.Scheduler do
  alias Oban.Job
  alias Odyssey.ObanWorker

  def schedule(workflow, opts \\ []) do
    ObanWorker.new(%{id: workflow.id}, opts)
  end
end
