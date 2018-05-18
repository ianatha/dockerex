defmodule Dockerex.LogStream do

  defp start(url, method, data, headers, options) do
    resp = HTTPoison.request!(method, url, data, headers, options)
    {resp}
  end

  defp continue({resp}) do
    receive do
      %HTTPoison.AsyncHeaders{} ->
        continue(resp)
      after 60_000 ->
        raise RuntimeError, "timed out: one minute with no headers in LogStream"
    end
  end

  defp continue(resp) do
    receive do
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        {[chunk], resp}
      %HTTPoison.AsyncEnd{} ->
        {:halt, resp}
      after 600_000 ->
        raise RuntimeError, "timed out: ten minutes of inactivity in LogStream"
    end
  end

  defp finish(_resp) do
    :ok
  end

  def stream(url, method, data, headers, options) do
    options = [{:stream_to, self}, {:timeout, :infinity} | options]
    Stream.resource(fn -> start(url, method, data, headers, options) end, &continue/1, &finish/1)
  end

end