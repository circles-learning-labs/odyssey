defmodule Odyssey.DB.WorkflowRun do
  @moduledoc """
  A workflow run is a a single run of a specified workflow.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Odyssey.DB.Term
  alias Odyssey.Repo
  alias Odyssey.State
  alias Odyssey.Workflow

  @type status :: :running | :suspended | :paused | :completed | :error

  schema "odyssey_workflow_runs" do
    field(:status, Ecto.Enum, values: [:running, :suspended, :paused, :completed, :error])
    field(:next_phase, :integer)
    field(:started_at, :utc_datetime_usec)
    field(:ended_at, :utc_datetime_usec)
    field(:phases, Term)
    field(:state, Term)
    field(:oban_job_id, :integer)
    timestamps()
  end

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer(),
          next_phase: integer(),
          started_at: DateTime.t(),
          ended_at: DateTime.t() | nil,
          state: term(),
          phases: Workflow.t(),
          status: status(),
          oban_job_id: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  def changeset(workflow_run, attrs) do
    workflow_run
    |> cast(attrs, [:status, :next_phase, :started_at, :ended_at, :state, :phases, :oban_job_id])
    |> validate_required([:status, :next_phase, :started_at, :state, :phases])
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
    |> Repo.insert!()
  end

  @spec update(t(), status(), State.t()) :: t()
  def update(workflow_run, new_status, next_phase \\ nil, state) do
    next_phase = next_phase || workflow_run.next_phase + 1

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

  def jump_to_phase(workflow_run, phase) do
    workflow_run
    |> changeset(%{next_phase: phase, status: :running})
    |> Repo.update!()
  end

  def set_oban_id(workflow_run, oban_id) do
    workflow_run
    |> changeset(%{oban_job_id: oban_id})
    |> Repo.update!()
  end
end
