defmodule Odyssey.ObanWorker do
  use Oban.Worker, queue: :workers

  alias Odyssey.DB.WorkflowRun

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{id: id}} = job) do
    case Repo.get(WorkflowRun, id) do
      %WorkflowRun{status: status} = workflow when status in [:running, :suspended] ->
        Workflow.run_next_phase(%{workflow | status: :running})

      nil ->
        :ok
    end
  end
end
