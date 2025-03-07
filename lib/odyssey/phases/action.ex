defmodule Odyssey.Phase.Action do
  alias Odyssey.Phase
  alias Odyssey.State

  @behaviour Phase

  defstruct [
    :name,
    :module,
    :args
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          module: module(),
          args: term()
        }

  @callback run(State.t()) :: Phase.result()

  def run(phase, state) do
    apply(phase.module, :run, [phase.args, state])
  end
end
