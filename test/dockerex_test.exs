defmodule DockerexTest do
  use ExUnit.Case
  doctest Dockerex

  test "linestream" do
    lines = ["this ", "is ", "one ", "line\nthis is another line\nignored"]
    |> Dockerex.LineStream.stream()
    |> Enum.to_list()
    assert lines == ["this is one line", "this is another line"]
  end
end
