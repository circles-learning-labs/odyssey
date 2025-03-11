defmodule Odyssey.DB.WorkflowRun do
  use Ecto.Schema

  import Ecto.Changeset

  alias Odyssey.DB.Term
  alias Odyssey.Repo
  alias Odyssey.State
  alias Odyssey.Workflow

  schema "odyssey_workflow_runs" do
    field(:status, Ecto.Enum, values: [:running, :suspended, :paused, :completed])
    field(:next_phase, :integer)
    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)
    field(:phases, Term)
    field(:state, Term)
    timestamps()
  end

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer(),
          next_phase: integer(),
          started_at: DateTime.t(),
          state: State.t(),
          phases: Workflow.t(),
          status: :running | :suspended | :paused | :completed,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  def changeset(workflow_run, attrs) do
    workflow_run
    |> cast(attrs, [:status, :next_phase, :started_at, :ended_at, :state])
    |> validate_required([:status, :next_phase, :started_at, :state])
  end

  def insert_new(workflow, state) do
    %__MODULE__{}
    |> changeset(%{
      status: :running,
      next_phase: 0,
      started_at: DateTime.utc_now(),
      state: state,
      phases: workflow
    })
    |> Repo.insert()
  end

  def update(workflow_run, new_status, state) do
    next_phase = workflow_run.next_phase + 1

    new_status =
      if next_phase >= length(workflow_run.phases) do
        :completed
      else
        new_status
      end

    ended_at =
      if new_status == :completed do
        DateTime.utc_now()
      else
        nil
      end

    workflow_run
    |> changeset(%{
      status: new_status,
      next_phase: next_phase,
      state: state,
      ended_at: ended_at
    })
    |> Repo.update!()
  end
end
