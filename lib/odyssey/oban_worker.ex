defmodule Odyssey.ObanWorker do
  @moduledoc """
  An Oban worker that, when run, executes the next phase of a workflow.
  """

  use Oban.Worker,
    queue: :odyssey_workers,
    unique: [
      keys: [:id, :phase],
      states: [:available, :executing, :scheduled, :retryable]
    ]

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Repo
  alias Odyssey.Workflow

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    case Repo.get(WorkflowRun, id) do
      %WorkflowRun{status: status} = workflow when status in [:running, :suspended] ->
        Workflow.run_next_phase(%{workflow | status: :running})

        :ok

      nil ->
        :ok
    end
  end
end
