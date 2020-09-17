# Firmata

This package implements the Firmata protocol in Elixir.

Firmata is a MIDI-based protocol for communicating with microcontrollers.

## Feature Completeness

**Implemented**

* Parser
* Handshake
  * Retreiving Version
  * Retreiving Firmware
  * Retreiving Pin Capabilities
  * Retreiving Analog Pin Mapping
* Toggle Analog Channel Reporting
* Set Pin Mode
* Digital Write
* I2C Read/Write
* String Data

**Planned**

* Digital Read

## Usage Example

A cloneable test application is available here [https://github.com/entone/firmata_test](https://github.com/entone/firmata_test)

The examples are tested against StandardFirmata.ino v2.5

### FirmataTest.Board
```elixir
defmodule FirmataTest.Board do
  use GenServer
  use Firmata.Protocol.Mixin
  require Logger

  @i2c_channel 98
  @read_bytes 32

  defmodule State do
    defstruct firmata: nil, sensors: []
  end

  def start_link(tty) do
    GenServer.start_link(__MODULE__, tty, name: __MODULE__)
  end

  def init(tty) do
    Logger.debug "Starting Firmata on port: #{inspect tty}"
    {:ok, firmata} = Firmata.Board.start_link(tty, [], :hardware_interface)
    Logger.info "Firmata Started: #{inspect firmata}"
    #Start the firmata initialization
    Firmata.Board.sysex_write(firmata, @firmware_query, <<>>)
    {:ok, %State{firmata: firmata}}
  end

  def init_board(state) do
    state |> init_i2c |> init_analog
  end

  defp init_i2c(state) do
    #Tell firmata to enable i2c
    Firmata.Board.sysex_write(state.firmata, @i2c_config, <<>>)
    Process.send_after(self(), :read_i2c, 0)
    state
  end

  defp init_analog(state) do
    FirmataTest.Analog.start_link(state.firmata, 0, :humidity)
    state
  end

  def handle_info(:read_i2c, state) do
    #Send write command to i2c device on channel 98, writes "R" which is the read command for Atlas Scientific stamps
    Firmata.Board.sysex_write(state.firmata, @i2c_request, <<@i2c_channel, @i2c_mode.write, "R">>)
    #most Atlas Scientific stamps take about 1000ms to return a value
    :timer.sleep(1000)
    #Read 32 bytes from i2c channel we wrote to a second ago.
    #We will get the response in handle_info(:firmata, {:i2c_response: value})
    Firmata.Board.sysex_write(state.firmata, @i2c_request, <<@i2c_channel, @i2c_mode.read, @read_bytes>>)
    # Take a reading every second
    Process.send_after(self(), :read_i2c, 1000)
    {:noreply, state}
  end

  def handle_info({:firmata, {:pin_map, pin_map}}, state) do
    #We wait until we know all the pin mappings before starting our interfaces
    Logger.info "Ready: Pin Map #{inspect pin_map}"
    {:noreply, state |> init_board}
  end

  def handle_info({:elixir_serial, _serial, data}, %{board: board} = state) do
    send(board, {:serial, data})
    {:noreply, state}
  end

  def handle_info({:firmata, {:version, major, minor}}, state) do
    Logger.info "Firmware Version: v#{major}.#{minor}"
    {:noreply, state}
  end

  def handle_info({:firmata, {:firmware_name, name}}, state) do
    Logger.info "Firmware Name: #{name}"
    {:noreply, state}
  end

  def handle_info({:firmata, {:string_data, value}}, state) do
    Logger.debug value
    {:noreply, state}
  end

  def handle_info({:firmata, {:i2c_response, <<channel::integer, 0, 0, 0, _rc::integer, value::binary>>} = payload}, state) do
    Logger.debug "Payload: #{inspect payload}"
    Logger.debug "Channel: #{channel}"
    Logger.debug "Raw Value: #{inspect value}"
    Logger.debug "Parsed Value: #{inspect value |> parse_ascii}"
    {:noreply, state}
  end

  def handle_info({:firmata, info}, state) do
    Logger.error "Unknown Firmata Data: #{inspect info}"
    {:noreply, state}
  end

  defp parse_ascii(data), do: for n <- data, n != <<0>>, into: "", do: n

end
```

### FirmataTest.Analog
```elixir
defmodule FirmataTest.Analog do
  use GenServer
  require Logger
  @report 1
  @no_report 0

  defmodule State do
    defstruct firmata: nil, channel: nil, value: 0
  end

  def start_link(firmata, channel, name \\ nil) do
    GenServer.start_link(__MODULE__, [firmata, channel], name: name)
  end

  def init([firmata, channel]) do
    #Set our analog channel/pin to "report" which means to report values to this process
    Firmata.Board.report_analog_channel(firmata, channel, @report)
    {:ok, %State{firmata: firmata, channel: channel}}
  end

  def handle_info({:firmata, {:analog_read, channel, value}}, %{channel: s_channel} = state) when channel === s_channel do
    Logger.debug "#{__MODULE__} on #{channel}: #{inspect value}"
    #Update our state with the latest value
    {:noreply, %State{state | value: value}}
  end

end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add firmata to your list of dependencies in `mix.exs`:

        def deps do
          [{:firmata, "~> 0.0.2"}]
        end

  2. Ensure firmata is started before your application:

        def application do
          [applications: [:firmata]]
        end
