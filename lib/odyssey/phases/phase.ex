defmodule Odyssey.Phase do
  alias Odyssey.State

  alias Odyssey.Phase.Action
  alias Odyssey.Phase.Pause

  @type result ::
          {:ok, State.t()}
          | {:suspend, State.t()}
          | {:stop, State.t()}
          | {:error, term(), State.t()}

  @type t :: Action | Pause

  @callback run(term(), State.t()) :: result()
  @callback suspend(term(), State.t()) :: {:ok, State.t()}
  @callback resume(term(), State.t()) :: result()
end
