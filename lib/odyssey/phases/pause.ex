defmodule Odyssey.Phase.Pause do
  alias Odyssey.State

  @type t :: %__MODULE__{
          name: String.t(),
          duration: Duration.unit_pair()
        }

  @callback run(State.t()) :: Phase.result()

  def run(phase, state) do
    {:suspend, state}
  end
end
