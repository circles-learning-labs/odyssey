defmodule Odyssey.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:odyssey_workflow_runs) do
      add :status, :string
      add :next_phase, :integer
      add :started_at, :utc_datetime
      add :ended_at, :utc_datetime
      add :state, :binary
      add :phases, :binary
      timestamps()
    end
  end
end
