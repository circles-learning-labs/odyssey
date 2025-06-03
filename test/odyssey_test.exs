defmodule OdysseyTest do
  use ExUnit.Case

  import Eventually

  alias Odyssey.DB.WorkflowRun
  alias Odyssey.Phase
  alias Odyssey.Phases.AddValue
  alias Odyssey.Phases.CallFun
  alias Odyssey.Phases.JumpToPhase
  alias Odyssey.Phases.Pause
  alias Odyssey.Phases.Slow
  alias Odyssey.Repo
  alias Odyssey.Workflow

  test "simple one-step workflow" do
    workflow = [%Phase{module: AddValue, args: 1}]

    start = DateTime.utc_now()

    %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

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

    %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

    assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)

    workflow_run = Repo.get(WorkflowRun, id)
    assert workflow_run.state == 3
  end

  test "phases with duplicate IDs" do
    workflow = [
      %Phase{id: :duplicate, module: AddValue, args: 1},
      %Phase{id: :duplicate, module: AddValue, args: 2}
    ]

    {:error, error} = Workflow.start(workflow, 0)
    assert error =~ "duplicate phase ID"
  end

  test "null state" do
    self = self()
    workflow = [%Phase{module: CallFun, args: fn _ -> send(self, :run) end}]

    %WorkflowRun{id: id} = Workflow.start!(workflow, nil)
    assert_receive(:run, 3_000)
    assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 4_000)
  end

  describe "{:suspend, period} return type" do
    test "pause workflow phase" do
      workflow = [%Phase{module: Pause, args: 2}, %Phase{module: AddValue, args: 1}]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

      Process.sleep(1_000)
      assert Repo.get(WorkflowRun, id).status == :suspended
      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 4_000)

      workflow_run = Repo.get(WorkflowRun, id)
      assert workflow_run.state == 1
    end

    test "pause workflow phase after action" do
      workflow = [
        %Phase{module: AddValue, args: 1},
        %Phase{module: Pause, args: 2},
        %Phase{module: AddValue, args: 1}
      ]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

      Process.sleep(1_000)
      assert Repo.get(WorkflowRun, id).status == :suspended
      assert Repo.get(WorkflowRun, id).state == 1
      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 4_000)

      workflow_run = Repo.get(WorkflowRun, id)
      assert workflow_run.state == 2
    end
  end

  describe ":jump return type" do
    test "phases with jump" do
      workflow = [
        %Phase{module: AddValue, args: 1},
        %Phase{module: JumpToPhase, args: :final},
        %Phase{module: AddValue, args: 50},
        %Phase{id: :final, module: AddValue, args: 1}
      ]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)

      workflow_run = Repo.get(WorkflowRun, id)
      assert workflow_run.state == 2
    end

    test "jump with invalid id" do
      workflow = [
        %Phase{module: AddValue, args: 1},
        %Phase{module: JumpToPhase, args: :invalid}
      ]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

      assert_eventually(Repo.get(WorkflowRun, id).status == :error, 3_000)

      workflow_run = Repo.get(WorkflowRun, id)
      assert workflow_run.state == 1
    end

    test "jump to a nil phase id" do
      workflow = [
        %Phase{module: AddValue, args: 1},
        %Phase{module: JumpToPhase, args: nil},
        %Phase{id: nil, module: AddValue, args: 1}
      ]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)

      assert_eventually(Repo.get(WorkflowRun, id).status == :error, 3_000)

      workflow_run = Repo.get(WorkflowRun, id)
      assert workflow_run.state == 1
    end
  end

  describe "stop/1" do
    test "stop a paused workflow" do
      workflow = [%Phase{module: Pause, args: 3}, %Phase{module: AddValue, args: 1}]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)
      %WorkflowRun{id: id} = Workflow.stop(id)

      assert Repo.get(WorkflowRun, id).status == :completed
      Process.sleep(5_000)
      assert Repo.get(WorkflowRun, id).state == 0
    end

    test "stop a running workflow" do
      workflow = [
        %Phase{module: AddValue, args: 1},
        %Phase{module: Slow, args: 5_000},
        %Phase{module: AddValue, args: 1}
      ]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)
      assert_eventually(Repo.get(WorkflowRun, id).state == 1)

      Workflow.stop(id)

      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 3_000)
      assert Repo.get(WorkflowRun, id).state == 1
    end

    test "stop a non-existant workflow" do
      assert Workflow.stop(-1) == nil
    end
  end

  describe "jump_to/2" do
    test "jump to future phase" do
      workflow = [%Phase{module: Pause, args: 60}, %Phase{module: AddValue, args: 1}]
      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)
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

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)
      assert_eventually(Repo.get(WorkflowRun, id).status == :suspended, 3_000)

      Workflow.jump_to(id, 0)

      assert_eventually(Repo.get(WorkflowRun, id).status == :suspended, 3_000)
      assert Repo.get(WorkflowRun, id).state == 2
    end

    test "jump to current phase" do
      workflow = [%Phase{module: Pause, args: 4}, %Phase{module: AddValue, args: 1}]

      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)
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
      %WorkflowRun{id: id} = Workflow.start!(workflow, 0)
      assert_eventually(Repo.get(WorkflowRun, id).status == :suspended, 2_000)

      Workflow.jump_to(id, 5)
      assert_eventually(Repo.get(WorkflowRun, id).status == :completed, 2_000)
      assert Repo.get(WorkflowRun, id).state == 0
    end
  end

  describe "runs/2" do
    setup do
      WorkflowRun
      |> Repo.delete_all()

      :ok
    end

    test "get currently active runs when non active" do
      assert Workflow.runs([:running]) == []
    end

    test "get currently active runs when active" do
      workflow = [%Phase{module: Pause, args: 4}, %Phase{module: AddValue, args: 1}]
      run = Workflow.start!(workflow, 0)

      assert_eventually(Repo.get(WorkflowRun, run.id).status == :suspended, 2_000)
      [db_run] = Workflow.runs([:suspended])
      assert db_run.id == run.id
      assert db_run.state == 0
      assert db_run.next_phase == 1
      assert db_run.phases == run.phases
    end

    test "limit the number of runs returned" do
      workflow = [%Phase{module: Pause, args: 4}, %Phase{module: AddValue, args: 1}]
      ids = 1..3 |> Enum.map(fn _ -> Workflow.start!(workflow, 0) end) |> Enum.map(& &1.id)

      [run1, run2] = Workflow.runs(:all, 2)
      assert run1.id in ids
      assert run2.id in ids
    end
  end
end
