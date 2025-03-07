defmodule Odyssey.Workflow do
  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.State

  @type id :: term()
  @type t :: [Phase.t()]

  @spec run(t(), State.t()) :: id()
  def run(workflow, state) do
    workflow_run = WorkflowRun.insert()
    Scheduler.schedule(workflow_run)
    workflow_run.id
  end

  @spec run_next_phase(WorkflowRun.t()) :: :ok
  def run_next_phase(%WorkflowRun{next_phase: next_phase, phases: phases} = run) do
    case Enum.at(phases, next_phase) do
      nil ->
        :ok

      phase ->
        phase
        |> Phase.run(state)
        |> handle_phase_result(run)
    end
  end

  @spec stop(id()) :: :ok
  def stop(id) do
  end

  @spec jump_to(id(), non_neg_integer()) :: :ok
  def jump_to(id, phase) do
  end

  defp handle_phase_result({:ok, state}, run) do
    run
    |> update_state(:running, state)
    |> run_next_phase()
  end

  defp handle_phase_result({:suspend, state}, run) do
    run
    |> update_state(:suspended, state)

    # TODO: Schedule a job to resume the workflow

    :ok
  end

  defp handle_phase_result({{:suspend, period}, state}, run) do
    run
    |> update_state(:suspended, state)

    :ok
  end

  defp handle_phase_result({:stop, state}, run) do
    run
    |> update_state(:complete, state)

    :ok
  end

  defp handle_phase_result({:error, reason, state}, run) do
    run
    |> update_state(:error, state)

    {:error, reason}
  end
end
