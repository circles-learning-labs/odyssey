defmodule Odyssey.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:odyssey_workflow_runs) do
      add :status, :string
      add :next_phase, :integer
      add :started_at, :utc_datetime_usec
      add :ended_at, :utc_datetime_usec
      add :state, :binary
      add :phases, :binary
      timestamps()
    end
  end
end
