defmodule Dockerex.LogStream do

  defp start(url, headers, options) do
    resp = HTTPoison.get!(url, headers, options)
    {resp, headers, options}
  end

  defp continue({resp, req_headers, req_options}) do
    receive do
      %HTTPoison.AsyncHeaders{headers: headers} ->
        loc = Enum.flat_map(headers, &get_redirect_header/1)
        case loc do
          [] ->
            continue(resp)
          [url] ->
            url
            |> start(req_headers, req_options)
            |> continue()
        end
      after 60_000 ->
        raise RuntimeError, "timed out: one minute wit no headers in LogStream"
    end
  end

  defp continue(resp) do
    receive do
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        {[chunk], resp}
      %HTTPoison.AsyncEnd{} ->
        {:halt, resp}
      after 3600_000 ->
        raise RuntimeError, "timed out: one hour of inactivity in LogStream"
    end
  end

  defp finish(_resp) do
    :ok
  end

  defp get_redirect_header({"Location", loc}), do: [loc]
  defp get_redirect_header({"location", loc}), do: [loc]
  defp get_redirect_header(_), do: []

  def stream(url, headers, options) do
    options = [{:stream_to, self} | options]
    Stream.resource(fn -> start(url, headers, options) end, &continue/1, &finish/1)
  end

end