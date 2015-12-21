defmodule Firmata.Protocol do
  use Firmata.Protocol.Mixin

  def parse({}, <<@report_version>>) do
    send(self, :report_version)
    {:major_version}
  end

  def parse({:major_version}, <<major>>) do
    send(self, {:major_version, major})
    {:minor_version}
  end

  def parse({:minor_version}, <<minor>>) do
    send(self, {:minor_version, minor})
    {}
  end

  def parse({}, <<@start_sysex>> = sysex) do
    {:sysex, sysex}
  end

  def parse({:sysex, sysex}, <<@end_sysex>>) do
    sysex = sysex<><<@end_sysex>>
    len = Enum.count(sysex)
    command = Enum.slice(sysex, 1, 1) |> List.first
    IO.inspect "sysex len #{len}, command: #{Hexate.encode(command)}"
    send(self, Firmata.Protocol.Sysex.parse(command, sysex))
    {}
  end

  def parse({:sysex, sysex}, byte) do
    {:sysex, sysex <> byte }
  end

  def parse(protocol_state, byte) do
    IO.puts "unknown: #{Hexate.encode(byte)}"
    protocol_state
  end
end
