defmodule Firmata.Protocol do
  use Firmata.Protocol.Mixin

  def parse({outbox, {}}, <<@report_version>>) do
    {outbox, {:report_version}}
  end

  def parse({outbox, {:report_version}}, <<major>>) do
    {outbox, {:report_version, major}}
  end

  def parse({outbox, {:report_version, major}}, <<minor>>) do
    {[ {:report_version, major, minor} | outbox ], {}}
  end

  def parse({outbox, {}}, <<@start_sysex>> = sysex) do
    {outbox, {:sysex, sysex}}
  end

  def parse({outbox, {:sysex, sysex}}, <<@end_sysex>>) do
    {[ Firmata.Protocol.Sysex.parse(sysex) | outbox ], {}}
  end

  def parse({outbox, {:sysex, sysex}}, byte) do
    {outbox, {:sysex, sysex <> byte }}
  end

  def parse({outbox, {}}, <<byte>>) when byte in @analog_message_range do
    {outbox, {:analog_read, byte &&& 0x0F}}
  end

  def parse({outbox, {:analog_read, pin}}, <<lsb>>) do
    {outbox, {:analog_read, pin, lsb}}
  end

  def parse({outbox, {:analog_read, pin, lsb}}, <<msb>>) do 
    {[{:analog_read, pin, lsb ||| (msb <<< 7)} | outbox], {}}
  end

  def parse(protocol_state, byte) do
    IO.inspect "unknown: #{to_hex(byte)}"
    protocol_state
  end

  def digital_write(pins, pin, value) do
    port = pin / 8 |> Float.floor |> round
    port_value = Enum.reduce(0..8, 0, fn(i, acc) ->
      index = 8 * port + i
      pin_record = Enum.at(pins, index)
      cond do
        pin_record && pin_record[:value] === 1 -> acc ||| (1 <<< i)
        true -> acc
      end
    end)
    <<@digital_message ||| port, port_value &&& 0x7F, (port_value >>> 7) &&& 0x7F>>
  end
end
