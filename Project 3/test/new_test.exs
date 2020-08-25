defmodule NewTest do
  use ExUnit.Case
  doctest New

  test "greets the world" do
    assert New.hello() == :world
  end
end
