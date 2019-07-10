defmodule Firmata.Protocol do
  use Firmata.Protocol.Mixin
  alias Firmata.Protocol.Sysex, as: Sysex

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
    {[ Sysex.parse(sysex) | outbox ], {}}
  end

  def parse({outbox, {:sysex, sysex}}, byte) do
    {outbox, {:sysex, sysex <> byte }}
  end

  def parse({outbox, {}}, <<byte>>) when byte in @analog_message_range do
    {outbox, {:analog_read, mask_n_lsb(byte, 4)}}
  end

  def parse({outbox, {:analog_read, pin}}, <<lsb>>) do
    {outbox, {:analog_read, pin, lsb}}
  end

  def parse({outbox, {:analog_read, pin, lsb}}, <<msb>>) do
    {[{:analog_read, pin, lsb ||| (msb <<< 7)} | outbox], {}}
  end

  def parse(protocol_state, _byte) do
    # IO.inspect "unknown: #{to_hex(byte)}"
    # We ignore what we do not understand
    protocol_state
  end

  def digital_write(pins, pin, value) do
    port = pin >>> 3 # divide by 8, returning int

    port_value = Enum.reduce(0..8, 0, fn(i, acc) ->
      index = 8 * port + i
      pin_record = Enum.at(pins, index)
      val = (pin_record && pin_record[:value]) || 0
      # If val == 0, acc will effectively be unchanged
      acc ||| (val <<< i)
    end)

    <<@digital_message ||| port, mask_n_lsb(port_value, 7), mask_n_lsb(port_value >>> 7, 7)>>
  end

  defp mask_n_lsb(number, n) do
    "1"
    |> to_charlist()
    |> Stream.cycle()
    |> Enum.take(n)
    |> List.to_integer(2)
    |> Bitwise.&&&(number)
  end

  defp print_binary(binary) do
    binary
    |> Enum.map(fn(<<int>>)-> int end)
    |> Enum.join(",")
    |> IO.puts
  end
end
