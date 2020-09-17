defmodule Firmata.Protocol.Sysex do
  require Logger
  use Firmata.Protocol.Mixin

  def parse(<<@start_sysex>> <> <<command>> <> sysex) do
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

  def parse(@i2c_response, sysex) do
    {:i2c_response, binary(sysex)}
  end

  def parse(@string_data, sysex) do
    {:string_data, binary(sysex)}
  end

  def parse(@sonar_data, sysex) do
    {:sonar_data, sonar_data(sysex)}
  end

  def parse(@pin_state_response, <<pin, mode, state>>) do
    {:pin_state, pin, mode, state}
  end

  def parse(bad_byte, sysex) do
  end

  def firmware_query(sysex) do
    sysex
    |> Enum.filter(fn <<b>> -> b in 32..126 end)
    |> Enum.join()
  end

  defp build_modes_array(supported_modes) do
    Enum.reduce(@modes, [], fn mode, modes ->
      case supported_modes &&& 1 <<< mode do
        0 -> modes
        _ -> [mode | modes]
      end
    end)
  end

  def capability_response(<<byte>>, state) do
    cond do
      byte === 127 ->
        modes_array =
          state[:supported_modes]
          |> build_modes_array()

        pin = [
          supported_modes: modes_array,
          mode: @unknown
        ]

        state
        |> Keyword.put(:pins, [pin | state[:pins]])
        |> Keyword.put(:supported_modes, 0)
        |> Keyword.put(:n, 0)

      state[:n] === 0 ->
        supported_modes = state[:supported_modes] ||| 1 <<< byte

        state
        |> Keyword.put(:supported_modes, supported_modes)
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

  def binary(sysex) do
    [value: sysex]
  end

  def sonar_data(<<trigger, lsb, msb>> = sysex) do
    val = (msb <<< 7) + lsb
    [value: val, pin: trigger]
  end

  def sonar_data(<<sysex>>) do
    [value: nil, pin: nil]
  end
end
