defmodule Firmata.Protocol.State do
  def unpack(state) do
    {state[:outbox], state[:parser]}
  end

  def pack({outbox, parser}, state) do
    %{state | outbox: outbox, parser: parser}
  end
end
