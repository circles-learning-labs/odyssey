defmodule Odyssey.Scheduler do
  @moduledoc """
  Schedules a workflow run for execution of its next phase.
  """

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.ObanWorker

  def schedule(workflow_run, opts \\ []) do
    %{id: workflow_run.id, phase: workflow_run.next_phase}
    |> ObanWorker.new(opts)
    |> Oban.insert()
  end

  def cancel(%WorkflowRun{oban_job_id: oban_job_id})
      when not is_nil(oban_job_id) do
    Oban.cancel_job(oban_job_id)
  end

  def cancel(_workflow_run) do
    :ok
  end
end
