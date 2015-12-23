# Firmata

This package implements the Firmata protocol in Elixir.

Firmata is a MIDI-based protocol for communicating with microcontrollers.

## Feature Completeness

Because I am new to Elixir, I don't want to write too much code up-front, so I'm implementing only what I require.

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

**Will Implement**

* Digital Read

## Usage Example

```elixir
defmodule App do
  require Serial
  use Firmata.Protocol.Modes
  alias Firmata.Board, as: Board

  @high 1
  @low 0

  def start_link(tty, baudrate, opts \\ []) do
    GenServer.start_link(__MODULE__, [tty, baudrate], opts)
  end

  def init([tty, baudrate]) do
    {:ok, serial} = Serial.start_link
    {:ok, board} = Board.start_link
    Serial.open(serial, tty)
    Serial.set_speed(serial, baudrate)
    Serial.connect(serial)
    {:ok, {board, serial}}
  end

  # Forward data over serial port to Firmata

  def handle_info({:elixir_serial, _serial, data}, {board, _} = state) do
    send(board, {:serial, data})
    {:noreply, state}
  end

  # Send data over serial port when Firmata asks us to

  def handle_info({:firmata, {:send_data, data}}, {_, serial} = state) do
    Serial.send_data(serial, data)
    {:noreply, state}
  end

  # Handle application-level messages from Firmata to design the app

  def handle_info({:firmata, {:version, major, minor}}, state) do
    IO.puts "Firmware Version: v#{major}.#{minor}"
    {:noreply, state}
  end

  def handle_info({:firmata, {:firmware_name, name}}, state) do
    IO.puts "Firmware Name: #{name}"
    {:noreply, state}
  end

  def handle_info({:firmata, {:pin_map, _pin_map}}, {board, _} = state) do
    IO.puts "Ready"

    Board.set_pin_mode(board, 13, @output)
    Board.digital_write(board, 13, @high)
    Board.report_analog_channel(board, 3, @high)

    spawn(fn->
      :timer.sleep 1000
      Board.report_analog_channel(board, 3, @low)
    end)

    {:noreply, state}
  end

  def handle_info({:firmata, {:analog_read, 3, value}}, state) do
    IO.inspect "analog pin 5: #{value}"
    {:noreply, state}
  end
end

{:ok, _ard} = App.start_link "/dev/cu.usbmodem1421", 57600
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add firmata to your list of dependencies in `mix.exs`:

        def deps do
          [{:firmata, "~> 0.0.1"}]
        end

  2. Ensure firmata is started before your application:

        def application do
          [applications: [:firmata]]
        end
