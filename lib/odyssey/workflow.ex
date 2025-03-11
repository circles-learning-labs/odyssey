defmodule Odyssey.Workflow do
  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.Repo
  alias Odyssey.Scheduler
  alias Odyssey.State

  @type id :: term()
  @type t :: [Phase.t()]

  @spec run(t(), State.t()) :: WorkflowRun.t()
  def run(workflow, state) do
    workflow_run = WorkflowRun.insert_new(workflow, state)
    Scheduler.schedule(workflow_run)
    workflow_run
  end

  @spec run_next_phase(WorkflowRun.t()) :: :ok
  def run_next_phase(
        %WorkflowRun{next_phase: next_phase, phases: phases, state: state} = workflow_run
      ) do
    case Enum.at(phases, next_phase) do
      nil ->
        :ok

      phase ->
        phase
        |> Phase.run(state)
        |> handle_phase_result(workflow_run)
    end
  end

  @spec stop(id()) :: :ok
  def stop(id) do
    Repo.transaction(fn ->
      case Repo.get(WorkflowRun, id) do
        %WorkflowRun{status: status, state: state} = workflow
        when status in [:running, :suspended] ->
          workflow
          |> WorkflowRun.update(:completed, state)
          |> Repo.update()

          :ok

        nil ->
          :ok
      end
    end)
  end

  @spec jump_to(id(), non_neg_integer()) :: :ok
  def jump_to(_id, _phase) do
    # TODO
    :ok
  end

  defp handle_phase_result({:ok, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:running, state)
    |> run_next_phase()
  end

  defp handle_phase_result({:suspend, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:suspended, state)

    # In this case it is up to the job to handle its own resumption

    :ok
  end

  defp handle_phase_result({{:suspend, period}, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:suspended, state)

    next_run_at = DateTime.add(DateTime.utc_now(), period, :second)
    Scheduler.schedule(workflow_run, scheduled_at: next_run_at)

    :ok
  end

  defp handle_phase_result({:stop, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:completed, state)

    :ok
  end

  defp handle_phase_result({:error, reason, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:error, state)

    {:error, reason}
  end
end
