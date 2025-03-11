defmodule OdysseyTest do
  use ExUnit.Case

  import Eventually

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.Phases.AddValue
  alias Odyssey.Phases.Pause
  alias Odyssey.Repo
  alias Odyssey.Workflow

  test "simple one-step workflow" do
    workflow = [%Phase{module: AddValue, args: 1}]

    start = DateTime.utc_now()

    %WorkflowRun{id: id} = Workflow.run(workflow, 0)
    assert_eventually(Repo.get(WorkflowRun, id).status == :completed)

    finish = DateTime.utc_now()

    workflow_run = Repo.get(WorkflowRun, id)
    assert workflow_run.state == 1
    assert workflow_run.next_phase == 1
    assert DateTime.compare(workflow_run.started_at, start) != :lt
    assert DateTime.compare(workflow_run.ended_at, finish) != :gt
    assert DateTime.compare(workflow_run.started_at, workflow_run.ended_at) != :gt
  end
end
