defmodule Firmata.Protocol do
  use Firmata.Protocol.Mixin
  use Firmata.Protocol.Modes
  alias Firmata.Protocol.Sysex, as: Sysex

  def parse({outbox, {}}, <<@report_version>>) do
    {outbox, {:report_version}}
  end

  def parse({outbox, {:report_version}}, <<major>>) do
    {outbox, {:report_version, major}}
  end

  def parse({outbox, {:report_version, major}}, <<minor>>) do
    {[{:report_version, major, minor} | outbox], {}}
  end

  def parse({outbox, {}}, <<@start_sysex>> = sysex) do
    {outbox, {:sysex, sysex}}
  end

  def parse({outbox, {:sysex, sysex}}, <<@end_sysex>>) do
    {[Sysex.parse(sysex) | outbox], {}}
  end

  def parse({outbox, {:sysex, sysex}}, byte) do
    {outbox, {:sysex, sysex <> byte}}
  end

  def parse({outbox, {}}, <<byte>>) when byte in @analog_message_range do
    {outbox, {:analog_report, byte &&& 0x0F}}
  end

  def parse({outbox, {:analog_report, pin}}, <<lsb>>) do
    {outbox, {:analog_report, pin, lsb}}
  end

  def parse({outbox, {:analog_report, pin, lsb}}, <<msb>>) do
    {[{:analog_report, pin, lsb ||| msb <<< 7} | outbox], {}}
  end

  def parse({outbox, {}}, <<byte>>) when byte in @digital_message_range do
    {outbox, {:digital_report, byte &&& 0x0F}}
  end

  def parse({outbox, {:digital_report, port}}, <<lsb>>) do
    {outbox, {:digital_report, port, lsb}}
  end

  def parse({outbox, {:digital_report, port, lsb}}, <<msb>>) do
    values =
      Enum.map(0..8, fn i ->
        port_index = 8 * port + i
        port_value = (lsb ||| msb <<< 7) >>> (i &&& 0x07) &&& 0x01
        {port_index, port_value}
      end)

    {[{:digital_report, values} | outbox], {}}
  end

  def parse(protocol_state, byte) do
    IO.inspect("unknown: #{to_hex(byte)}")
    # We ignore what we do not understand
    protocol_state
  end

  def digital_write(pins, pin) do
    float = pin / 8
    port = float |> Float.floor() |> round

    port_value =
      Enum.reduce(0..8, 0, fn i, acc ->
        index = 8 * port + i
        pin_record = Enum.at(pins, index)

        if pin_record && pin_record[:value] === 1 do
          acc ||| 1 <<< i
        else
          acc
        end
      end)

    <<@digital_message ||| port, port_value &&& 0x7F, port_value >>> 7 &&& 0x7F>>
  end

  def report_digital_port(pins, pin) do
    float = pin / 8
    port = float |> Float.floor() |> round

    port_value =
      Enum.reduce(0..8, 0, fn i, acc ->
        index = 8 * port + i
        pin_record = Enum.at(pins, index)

        if pin_record && pin_record[:report] === 1 do
          acc ||| 1 <<< i
        else
          acc
        end
      end)

    <<@report_digital ||| port, port_value &&& 0x7F>>
  end

  def analog_write(pin, value) do
    <<@report_analog ||| pin, value &&& 0x7F, value >>> 7 &&& 0x7F>>
  end
end
