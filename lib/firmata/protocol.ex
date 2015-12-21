defmodule Firmata.Protocol.Mixin do
  defmacro __using__(_) do
    quote location: :keep do
      use Bitwise

      @input 0x00
      @output 0x01
      @analog 0x02
      @pwm 0x03
      @servo 0x04
      @shift 0x05
      @i2c 0x06
      @onewire 0x07
      @stepper 0x08
      @serial 0x0a
      @ignore 0x7f
      @ping_read 0x75
      @unknown 0x10

      @modes [
        @input,
        @output,
        @analog,
        @pwm,
        @servo,
        @shift,
        @i2c,
        @onewire,
        @stepper,
        @serial,
        @ignore,
        @ping_read,
        @unknown
      ]
      @low  0
      @high 1

      # Internal: Fixnum byte command for protocol version
      @report_version 0xF9
      # Internal: Fixnum byte command for system reset
      @system_reset 0xFF
      # Internal: Fixnum byte command for digital I/O message
      @digital_message 0x90
      # Pubilc: Fixnum byte for range for digital pins for digital 2 byte data format
      @digital_message_range 0x90..0x9f
      # internal: fixnum byte command for an analog i/o message
      @analog_message 0xe0
      # internal: fixnum byte range for analog pins for analog 14-bit data format
      @analog_message_range 0xe0..0xef
      # internal: fixnum byte command to report analog pin
      @report_analog 0xc0
      # internal: fixnum byte command to report digital port
      @report_digital 0xd0
      # internal: fixnum byte command to set pin mode (i/o)
      @pin_mode  0xf4
      # internal: fixnum byte command for start of sysex message
      @start_sysex 0xf0
      # internal: fixnum byte command for end of sysex message
      @end_sysex 0xf7
      # internal: fixnum byte sysex command for capabilities query
      @capability_query 0x6b
      # internal: fixnum byte sysex command for capabilities response
      @capability_response 0x6c
      # internal: fixnum byte sysex command for pin state query
      @pin_state_query 0x6d
      # internal: fixnum byte sysex command for pin state response
      @pin_state_response 0x6e
      # internal: fixnum byte sysex command for analog mapping query
      @analog_mapping_query 0x69
      # internal: fixnum byte sysex command for analog mapping response
      @analog_mapping_response 0x6a
      # internal: fixnum byte sysex command for firmware query and response
      @firmware_query 0x79
    end
  end
end

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

defmodule Firmata.Protocol.CapabilityResponse do
  use Firmata.Protocol.Mixin

  def parse(sysex) do
    capstate = [supported_modes: 0, n: 0, pins: []]
    len = Enum.count(sysex)
    sysex = Enum.slice(sysex, 2, len - 3)
    capstate = Enum.reduce(sysex, capstate, fn (<<byte>>, capstate) ->
      cond do
        byte === 127 ->
        modes_array = Enum.reduce(@modes, [], fn(mode, modes) ->
          case (capstate[:supported_modes] &&& (1 <<< mode)) do
            0 -> modes
            _ -> [ mode | modes]
          end
        end)
        IO.inspect modes_array
        pin = [
          supported_modes: modes_array,
          mode: @unknown
        ]
        Keyword.put(capstate, :pins, [ pin | capstate[:pins] ])
        |> Keyword.put(:supported_modes, 0)
        |> Keyword.put(:n, 0)
        capstate[:n] === 0 ->
          supported_modes = capstate[:supported_modes] ||| (1 <<< byte);
          Keyword.put(capstate, :supported_modes, supported_modes)
          |> Keyword.put(:n, capstate[:n] ^^^ 1)
        true ->
          Keyword.put(capstate, :n, capstate[:n] ^^^ 1)
      end
    end)
    capstate[:pins]
  end
end

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
    case command do
      <<@firmware_query>> ->
        firmware_name = Enum.slice(sysex, 4, len - 5)
        |> Enum.reject(fn(<<b>>)-> b === 0 end)
        |> Enum.join()
        state = Keyword.put(state, :firmware_name, firmware_name)
        {state, {}}
      <<@capability_response>> ->
        pins = Firmata.Protocol.CapabilityResponse.parse(sysex)
        state = Keyword.put(state, :pins, pins)
        IO.inspect state[:pins]
        {state, {}}
      _ ->
        IO.puts "Bad byte"
        {state, {}}
    end
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
