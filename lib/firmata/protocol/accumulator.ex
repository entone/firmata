defmodule Firmata.Protocol.Accumulator do
  def unpack(state) do
    {state, state[:_protocol_state] || {}}
  end

  def pack({state, pstate}) do
    case tuple_size(pstate) do
      0-> state
      _-> Keyword.put(state, :_protocol_state, pstate)
    end
  end
end
