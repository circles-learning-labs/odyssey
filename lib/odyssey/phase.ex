defmodule Odyssey.Phase do
  @moduledoc """
  A phase is a single step in a workflow.
  """

  alias Odyssey.State

  @type result ::
          {:ok, State.t()}
          | {:suspend, State.t()}
          | {{:suspend, non_neg_integer()}, State.t()}
          | {:stop, State.t()}
          | {:error, term(), State.t()}

  @callback run(term(), State.t()) :: result()

  defstruct [
    :module,
    :args,
    name: ""
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          module: module(),
          args: term()
        }

  def run(phase, state) do
    apply(phase.module, :run, [phase.args, state])
  end
end
