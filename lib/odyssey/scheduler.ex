defmodule Odyssey.Scheduler do
  alias Odyssey.ObanWorker

  def schedule(workflow_run, opts \\ []) do
    %{id: workflow_run.id}
    |> ObanWorker.new(opts)
    |> Oban.insert()
  end
end
