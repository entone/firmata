defmodule Firmata.Protocol do
  use Firmata.Protocol.Mixin

  def parse({state, {}}, <<@report_version>>) do
    query_capabilities(state[:serial])
    {state, {:major_version}}
  end

  def parse({state, {:major_version}}, <<major>>) do
    {Keyword.put(state, :major_version, major), {:minor_version}}
  end

  def parse({state, {:minor_version}}, <<minor>>) do
    {Keyword.put(state, :minor_version, minor), {}}
  end

  def parse({state, {}}, <<@start_sysex>> = sysex) do
    {state, {:sysex, sysex}}
  end

  def parse({state, {:sysex, sysex}}, <<@end_sysex>>) do
    sysex = sysex<><<@end_sysex>>
    len = Enum.count(sysex)
    command = Enum.slice(sysex, 1, 1) |> List.first
    IO.inspect "sysex len #{len}, command: #{Hexate.encode(command)}"
    state = Firmata.Protocol.Sysex.parse(state, command, sysex)
    IO.inspect state
    {state, {}}
  end

  def parse({state, {:sysex, sysex}}, byte) do
    {state, {:sysex, sysex <> byte }}
  end

  def parse(state, byte) do
    IO.puts "unknown: #{Hexate.encode(byte)}"
    state
  end

  def query_capabilities(serial) do
    IO.puts "query caps"
    Serial.send_data(serial, <<@start_sysex, @capability_query, @end_sysex>>)
  end
end
