defmodule Odyssey.DB.Term do
  @moduledoc """
  A custom Ecto type for storing arbitrary BEAM terms in the database.
  """

  use Ecto.Type

  @spec type() :: module()
  def type do
    __MODULE__
  end

  @spec cast(term()) :: {:ok, term()}
  def cast(value) do
    {:ok, value}
  end

  @spec load(term()) :: {:ok, term()} | :error
  def load(value) do
    {:ok, :erlang.binary_to_term(value)}
  rescue
    _ -> :error
  end

  @spec dump(term()) :: {:ok, term()}
  def dump(value) do
    {:ok, :erlang.term_to_binary(value)}
  end
end
