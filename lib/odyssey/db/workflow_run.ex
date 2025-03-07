defmodule Odyssey.DB.WorkflowRun do
  use Ecto.Schema

  import Ecto.Changeset

  alias Odyssey.DB.Term
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

  def changeset(params, attrs) do
    %__MODULE__{}
    |> cast(params, [:status, :next_phase, :started_at, :ended_at, :state])
    |> validate_required([:status, :next_phase, :started_at, :state])
  end
end
