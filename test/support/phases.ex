defmodule Odyssey.Phases do
  @moduledoc """
  A collection of phases for use in test workflows
  """

  alias Odyssey.Phase

  defmodule AddValue do
    @moduledoc """
    A phase that adds a value to the state
    """

    @behaviour Phase

    @impl Phase
    def run(to_add, state) do
      {:ok, state + to_add}
    end
  end

  defmodule Pause do
    @moduledoc """
    A phase that pauses the workflow
    """

    @behaviour Phase

    @impl Phase
    def run(pause_time, state) do
      {{:suspend, pause_time}, state}
    end
  end

  defmodule Stop do
    @moduledoc """
    A phase that stops the workflow
    """

    @behaviour Phase

    @impl Phase
    def run(_args, state) do
      {:stop, state}
    end
  end
end
