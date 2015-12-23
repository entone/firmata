defmodule Firmata.Protocol.Sysex do
  use Firmata.Protocol.Mixin

  def parse(<<@start_sysex>><><<command>><>sysex) do
    parse(command, sysex)
  end

  def parse(@firmware_query, sysex) do
    {:firmware_name, firmware_query(sysex)}
  end

  def parse(@capability_response, sysex) do
    {:capability_response, capability_response(sysex)[:pins]}
  end

  def parse(@analog_mapping_response, sysex) do
    {:analog_mapping_response, analog_mapping_response(sysex)}
  end

  def parse(bad_byte, _sysex) do
    IO.puts "Unrecognized sysex command #{to_hex(bad_byte)}"
  end

  def firmware_query(sysex) do
    sysex
    |> Enum.filter(fn(<<b>>)-> b in 32..126 end)
    |> Enum.join()
  end

  def capability_response(<<byte>>, state) do
    cond do
      byte === 127 ->
      modes_array = Enum.reduce(@modes, [], fn(mode, modes) ->
        case (state[:supported_modes] &&& (1 <<< mode)) do
          0 -> modes
          _ -> [ mode | modes]
        end
      end)
      pin = [
        supported_modes: modes_array,
        mode: @unknown
      ]
      Keyword.put(state, :pins, [ pin | state[:pins] ])
      |> Keyword.put(:supported_modes, 0)
      |> Keyword.put(:n, 0)
      state[:n] === 0 ->
        supported_modes = state[:supported_modes] ||| (1 <<< byte);
        Keyword.put(state, :supported_modes, supported_modes)
        |> Keyword.put(:n, state[:n] ^^^ 1)
      true ->
        Keyword.put(state, :n, state[:n] ^^^ 1)
    end
  end

  def capability_response(sysex) do
    state = [supported_modes: 0, n: 0, pins: []]
    sysex |> Enum.reduce(state, &capability_response/2)
  end

  def analog_mapping_response(<<127>>) do
    [value: nil, report: 0]
  end

  def analog_mapping_response(<<channel>>) do
    [value: nil, analog_channel: channel, report: 0]
  end

  def analog_mapping_response(sysex) do
    sysex |> Enum.map(&analog_mapping_response/1)
  end
end

