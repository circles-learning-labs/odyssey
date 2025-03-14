defmodule OdysseyTest do
  use ExUnit.Case

  import Eventually

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.Phases.AddValue
  alias Odyssey.Phases.Pause
  alias Odyssey.Phases.Stop
  alias Odyssey.Repo
  alias Odyssey.Workflow

  test "simple one-step workflow" do
    workflow = [%Phase{module: AddValue, args: 1}]

    start = DateTime.utc_now()

    %WorkflowRun{id: id} = Workflow.start(workflow, 0)

    assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)

    finish = DateTime.utc_now()

    workflow_run = Repo.get(WorkflowRun, id)
    assert workflow_run.state == 1
    assert workflow_run.next_phase == 1
    assert DateTime.compare(workflow_run.started_at, start) != :lt
    assert DateTime.compare(workflow_run.ended_at, finish) != :gt
    assert DateTime.compare(workflow_run.started_at, workflow_run.ended_at) != :gt
  end

  test "multi-step workflow" do
    workflow = [%Phase{module: AddValue, args: 1}, %Phase{module: AddValue, args: 2}]

    %WorkflowRun{id: id} = Workflow.start(workflow, 0)

    assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)

    workflow_run = Repo.get(WorkflowRun, id)
    assert workflow_run.state == 3
  end

  test "pause workflow phase" do
    workflow = [%Phase{module: Pause, args: 2}, %Phase{module: AddValue, args: 1}]

    %WorkflowRun{id: id} = Workflow.start(workflow, 0)

    Process.sleep(1_000)
    assert Repo.get(WorkflowRun, id).status == :suspended
    assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 4_000)

    workflow_run = Repo.get(WorkflowRun, id)
    assert workflow_run.state == 1
  end

  test "stop a paused workflow" do
    workflow = [%Phase{module: Pause, args: 3}, %Phase{module: AddValue, args: 1}]

    %WorkflowRun{id: id} = Workflow.start(workflow, 0)
    Workflow.stop(id)

    assert Repo.get(WorkflowRun, id).status == :completed
    Process.sleep(5_000)
    assert Repo.get(WorkflowRun, id).state == 0
  end

  test "stop a workflow" do
    workflow = [%Phase{module: Stop, args: 1}, %Phase{module: AddValue, args: 1}]

    %WorkflowRun{id: id} = Workflow.start(workflow, 0)

    assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)
    assert Repo.get(WorkflowRun, id).state == 0
  end

  describe "jump_to/2" do
    test "jump to future phase" do
      workflow = [%Phase{module: Pause, args: 60}, %Phase{module: AddValue, args: 1}]
      %WorkflowRun{id: id} = Workflow.start(workflow, 0)
      Workflow.jump_to(id, 1)

      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)
      assert Repo.get(WorkflowRun, id).state == 1
    end

    test "jump to past phase" do
      workflow = [
        %Phase{module: AddValue, args: 1},
        %Phase{module: Pause, args: 60},
        %Phase{module: AddValue, args: 500}
      ]

      %WorkflowRun{id: id} = Workflow.start(workflow, 0)
      assert_eventually(Repo.get(WorkflowRun, id).status == :suspended, 3_000)

      Workflow.jump_to(id, 0)

      assert_eventually(Repo.get(WorkflowRun, id).status == :suspended, 3_000)
      assert Repo.get(WorkflowRun, id).state == 2
    end

    test "jump to current phase" do
      workflow = [%Phase{module: Pause, args: 4}, %Phase{module: AddValue, args: 1}]

      %WorkflowRun{id: id} = Workflow.start(workflow, 0)
      Process.sleep(2_000)

      Workflow.jump_to(id, 0)

      Process.sleep(3_000)
      workflow_run = Repo.get(WorkflowRun, id)
      assert workflow_run.status == :suspended
      assert workflow_run.state == 0

      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)
      assert Repo.get(WorkflowRun, id).state == 1
    end

    test "jump to non-existent phase" do
      workflow = [%Phase{module: Pause, args: 4}, %Phase{module: AddValue, args: 1}]
      %WorkflowRun{id: id} = Workflow.start(workflow, 0)
      assert_eventually(Repo.get(WorkflowRun, id).status == :suspended, 2_000)

      Workflow.jump_to(id, 5)
      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 2_000)
      assert Repo.get(WorkflowRun, id).state == 0
    end
  end
end
