defmodule Odyssey.Scheduler do
  @moduledoc """
  Schedules a workflow run for execution of its next phase.
  """

  alias Odyssey.ObanWorker

  def schedule(workflow_run, opts \\ []) do
    %{id: workflow_run.id, phase: workflow_run.next_phase}
    |> ObanWorker.new(opts)
    |> Oban.insert()
  end
end
