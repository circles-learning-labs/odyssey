defmodule Odyssey.State do
  @moduledoc """
  The state of a workflow run. In reality this can be any term, since it is up to the workflow
  phases to interpret and mutate the state as needed.
  """

  @type t :: term()
end
