defmodule Firmata.Protocol.Accumulator do
  def unpack(state) do
    state[:_protocol_state] || {}
  end

  def pack(protocol_state, state) do
    case tuple_size(protocol_state) do
      0-> state
      _-> Keyword.put(state, :_protocol_state, protocol_state)
    end
  end
end
