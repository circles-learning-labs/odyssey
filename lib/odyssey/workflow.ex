defmodule Odyssey.Workflow do
  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.State

  @type id :: term()
  @type t :: [Phase.t()]

  @spec run(t(), State.t()) :: id()
  def run(workflow, state) do
    WorkflowRun.insert()
  end

  def run_next_phase(%WorkflowRun{next_phase: next_phase, phases: phases}) do
    case Enum.at(phases, next_phase) do
      nil ->
        :ok

      phase ->
        phase.__struct__.run(phase, state)
    end
  end

  def stop(id) do
  end

  def next(id) do
  end

  def previous(id) do
  end
end
