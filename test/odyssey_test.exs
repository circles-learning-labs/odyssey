defmodule OdysseyTest do
  use ExUnit.Case
  doctest Odyssey

  test "greets the world" do
    assert Odyssey.hello() == :world
  end
end
