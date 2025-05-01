defmodule Odyssey.DB.WorkflowRun do
  @moduledoc """
  A workflow run is a a single run of a specified workflow.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [where: 3, order_by: 2, limit: 2]

  alias Odyssey.DB.Term
  alias Odyssey.Phase
  alias Odyssey.State
  alias Odyssey.Workflow

  @type status :: :running | :suspended | :completed | :error

  schema "odyssey_workflow_runs" do
    field(:name, :string)
    field(:status, Ecto.Enum, values: [:running, :suspended, :completed, :error])
    field(:next_phase, :integer)
    field(:started_at, :utc_datetime_usec)
    field(:ended_at, :utc_datetime_usec)
    field(:phases, Term)
    field(:state, Term)
    field(:oban_job_id, :integer)
    timestamps()
  end

  @type t :: %__MODULE__{
          id: integer(),
          name: String.t(),
          next_phase: Phase.index(),
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
    |> cast(attrs, [
      :name,
      :status,
      :next_phase,
      :started_at,
      :ended_at,
      :state,
      :phases,
      :oban_job_id
    ])
    |> validate_required([:status, :next_phase, :started_at, :phases])
  end

  def insert_new(workflow, name, state) do
    %__MODULE__{}
    |> changeset(%{
      name: name,
      status: :running,
      next_phase: 0,
      started_at: DateTime.utc_now(),
      state: state,
      phases: workflow
    })
    |> Odyssey.repo().insert!()
  end

  @spec update(t(), status(), State.t()) :: t()
  def update(workflow_run, new_status, next_phase \\ nil, state) do
    next_phase = next_phase || workflow_run.next_phase + 1

    new_status =
      if next_phase >= length(workflow_run.phases) and new_status != :error do
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
    |> Odyssey.repo().update!()
  end

  @spec jump_to_index(t(), Phase.index()) :: t()
  def jump_to_index(workflow_run, index) do
    workflow_run
    |> changeset(%{next_phase: index, status: :running})
    |> Odyssey.repo().update!()
  end

  @spec jump_to_phase(t(), Phase.id()) :: t()
  def jump_to_phase(workflow_run, phase_id) do
    case Enum.find_index(workflow_run.phases, &(&1.id == phase_id)) do
      nil ->
        update(workflow_run, :error, workflow_run.state)
        {:error, "Phase ID #{inspect(phase_id)} not found in workflow"}

      index ->
        workflow_run
        |> jump_to_index(index)
    end
  end

  def set_oban_id(workflow_run, oban_id) do
    workflow_run
    |> changeset(%{oban_job_id: oban_id})
    |> Odyssey.repo().update!()
  end

  def by_statuses(:all, limit) do
    __MODULE__
    |> order_limit(limit)
  end

  def by_statuses(statuses, limit) do
    __MODULE__
    |> where([w], w.status in ^statuses)
    |> order_limit(limit)
  end

  def by_name(name, limit) do
    __MODULE__
    |> where([w], w.name == ^name)
    |> order_limit(limit)
  end

  defp order_limit(query, limit) do
    query
    |> order_by(desc: :started_at)
    |> limit(^limit)
    |> Odyssey.repo().all()
  end
end
