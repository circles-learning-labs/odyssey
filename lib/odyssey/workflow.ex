defmodule Odyssey.Workflow do
  @moduledoc """
  A workflow is a sequence of phases that are executed in order.
  """

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.Scheduler
  alias Odyssey.State

  @type id :: term()
  @type t :: [Phase.t()]

  @spec start!(t(), String.t() | nil, State.t()) :: WorkflowRun.t()
  def start!(workflow, name \\ nil, state) do
    case start(workflow, name, state) do
      {:ok, workflow_run} ->
        workflow_run

      {:error, reason} ->
        raise "Failed to start workflow: #{inspect(reason)}"
    end
  end

  @spec start(t(), String.t() | nil, State.t()) :: {:ok, WorkflowRun.t()} | {:error, term()}
  def start(workflow, name \\ nil, state) do
    case validate_workflow(workflow) do
      :ok ->
        Odyssey.repo().transaction(fn ->
          workflow
          |> WorkflowRun.insert_new(name, state)
          |> run_immediate()
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec run_next_phase(WorkflowRun.t()) :: WorkflowRun.t() | {:error, term()}
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

  def run_next_phase({:error, _error} = e), do: e

  @spec stop(id()) :: WorkflowRun.t() | nil
  def stop(id) do
    {:ok, result} =
      Odyssey.repo().transaction(fn ->
        case Odyssey.repo().get(WorkflowRun, id) do
          %WorkflowRun{status: status, state: state} = workflow_run
          when status in [:running, :suspended] ->
            Scheduler.cancel(workflow_run)
            WorkflowRun.update(workflow_run, :completed, state)

          nil ->
            nil
        end
      end)

    result
  end

  @spec jump_to(id(), Phase.index()) :: WorkflowRun.t() | nil
  def jump_to(workflow_id, index) do
    {:ok, result} =
      Odyssey.repo().transaction(fn ->
        case Odyssey.repo().get(WorkflowRun, workflow_id) do
          %WorkflowRun{status: status} = workflow_run when status in [:running, :suspended] ->
            Scheduler.cancel(workflow_run)

            workflow_run
            |> WorkflowRun.jump_to_index(index)
            |> run_immediate()

          _ ->
            nil
        end
      end)

    result
  end

  @spec runs([WorkflowRun.status()] | :all, non_neg_integer()) :: [WorkflowRun.t()]
  def runs(statuses, limit \\ 100) do
    WorkflowRun.by_statuses(statuses, limit)
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

  defp handle_phase_result({{:jump, nil}, state}, workflow_run) do
    WorkflowRun.update(workflow_run, :error, state)
  end

  defp handle_phase_result({{:jump, phase_id}, state}, workflow_run) do
    workflow_run
    |> WorkflowRun.update(:running, state)
    |> WorkflowRun.jump_to_phase(phase_id)
    |> run_next_phase()
  end

  defp handle_phase_result({{:suspend, period}, state}, workflow_run) do
    {:ok, workflow_run} =
      Odyssey.repo().transaction(fn ->
        workflow_run = WorkflowRun.update(workflow_run, :suspended, state)
        {:ok, oban_job} = Scheduler.schedule(workflow_run, schedule_in: period)
        WorkflowRun.set_oban_id(workflow_run, oban_job.id)
      end)

    workflow_run
  end

  defp handle_phase_result({:stop, state}, workflow_run) do
    WorkflowRun.update(workflow_run, :completed, state)
  end

  defp handle_phase_result({{:error, reason}, state}, workflow_run) do
    WorkflowRun.update(workflow_run, :error, state)
    {:error, reason}
  end

  defp run_immediate(workflow_run) do
    {:ok, oban_job} = Scheduler.schedule(workflow_run)
    WorkflowRun.set_oban_id(workflow_run, oban_job.id)
  end

  defp validate_workflow(workflow) do
    with {_, true} <- {:phase, Enum.all?(workflow, &is_struct(&1, Phase))},
         {_, true} <- {:unique_ids, unique_phase_ids(workflow)} do
      :ok
    else
      {:phase, false} ->
        {:error, "Workflow contains elements that are not Odyssey.Phase structs"}

      {:unique_ids, false} ->
        {:error, "Workflow contains duplicate phase IDs"}
    end
  end

  defp unique_phase_ids(workflow) do
    ids = workflow |> Enum.map(& &1.id) |> Enum.reject(&is_nil/1)
    unique_ids = Enum.uniq(ids)
    length(ids) == length(unique_ids)
  end
end
