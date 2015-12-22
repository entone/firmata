defmodule Firmata.Protocol.State do
  def unpack(state) do
    {state[:outbox], state[:parser]}
  end

  def pack({outbox, parser}, state) do
    state
    |> Keyword.put(:outbox, outbox)
    |> Keyword.put(:parser, parser)
  end
end
