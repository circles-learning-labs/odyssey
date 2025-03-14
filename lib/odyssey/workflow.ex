defmodule Odyssey.Workflow do
  @moduledoc """
  A workflow is a sequence of phases that are executed in order.
  """

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.Repo
  alias Odyssey.Scheduler
  alias Odyssey.State

  @type id :: term()
  @type t :: [Phase.t()]

  @spec start(t(), State.t()) :: WorkflowRun.t()
  def start(workflow, state) do
    {:ok, workflow_run} =
      Repo.transaction(fn ->
        WorkflowRun.insert_new(workflow, state)
        |> run_immediate()
      end)

    workflow_run
  end

  @spec run_next_phase(WorkflowRun.t()) :: WorkflowRun.t()
  def run_next_phase(
        %WorkflowRun{next_phase: next_phase, phases: phases, state: state} = workflow_run
      ) do
    case Enum.at(phases, next_phase) do
      nil ->
        WorkflowRun.update(workflow_run, :completed, workflow_run.next_phase, state)

      phase ->
        phase
        |> Phase.run(state)
        |> handle_phase_result(workflow_run)
    end
  end

  @spec stop(id()) :: WorkflowRun.t() | nil
  def stop(id) do
    Repo.transaction(fn ->
      case Repo.get(WorkflowRun, id) do
        %WorkflowRun{status: status, state: state} = workflow_run
        when status in [:running, :suspended] ->
          WorkflowRun.update(workflow_run, :completed, state)
          :ok

        nil ->
          nil
      end
    end)
  end

  @spec jump_to(id(), non_neg_integer()) :: WorkflowRun.t() | nil
  def jump_to(id, phase) do
    {:ok, workflow_run} =
      Repo.transaction(fn ->
        case Repo.get(WorkflowRun, id) do
          %WorkflowRun{status: status} = workflow_run when status in [:running, :suspended] ->
            Scheduler.cancel(workflow_run)

            workflow_run
            |> WorkflowRun.jump_to_phase(phase)
            |> run_immediate()

          _ ->
            nil
        end
      end)

    workflow_run
  end

  @spec handle_phase_result(Phase.result(), WorkflowRun.t()) :: WorkflowRun.t()
  defp handle_phase_result({:ok, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:running, state)
    |> run_next_phase()
  end

  defp handle_phase_result({:suspend, state}, workflow_run) do
    WorkflowRun.update(workflow_run, :suspended, state)

    # In this case it is up to the job to handle its own resumption
  end

  defp handle_phase_result({{:suspend, period}, state}, workflow_run) do
    {:ok, workflow_run} =
      Repo.transaction(fn ->
        workflow_run = WorkflowRun.update(workflow_run, :suspended, state)
        {:ok, oban_job} = Scheduler.schedule(workflow_run, schedule_in: period)
        WorkflowRun.set_oban_id(workflow_run, oban_job.id)
      end)

    workflow_run
  end

  defp handle_phase_result({:stop, state}, workflow_run) do
    WorkflowRun.update(workflow_run, :completed, state)
  end

  defp handle_phase_result({:error, reason, state}, workflow_run) do
    WorkflowRun.update(workflow_run, :error, state)
    {:error, reason}
  end

  defp run_immediate(workflow_run) do
    {:ok, oban_job} = Scheduler.schedule(workflow_run)
    WorkflowRun.set_oban_id(workflow_run, oban_job.id)
  end
end
