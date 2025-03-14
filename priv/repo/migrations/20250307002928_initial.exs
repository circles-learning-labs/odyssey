defmodule Odyssey.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:odyssey_workflow_runs) do
      add :status, :string, null: false
      add :next_phase, :integer, null: false
      add :started_at, :utc_datetime_usec, null: false
      add :ended_at, :utc_datetime_usec
      add :state, :binary, null: false
      add :phases, :binary, null: false
      add :oban_job_id, :integer
      timestamps()
    end
  end
end
