defmodule Dockerex.LineStream do
  def stream(stream) do
    Stream.transform(stream, "", &handle(&2, &1, []))
  end
  defp handle(acc, "\n" <> chunk, result) do
    handle("", chunk, [acc | result])
  end
  defp handle(acc, <<c :: 8, chunk :: binary>>, result) do
    handle(<<acc :: binary, c :: 8>>, chunk, result)
  end
  defp handle(acc, "", result) do
    {Enum.reverse(result), acc}
  end
end
