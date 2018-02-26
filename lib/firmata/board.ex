defmodule Firmata.Board do
  use GenServer
  use Firmata.Protocol.Mixin
  require Logger
  alias Firmata.Protocol.State, as: ProtocolState

  @initial_state %{
    pins: [],
    outbox: [],
    processor_pid: nil,
    parser: {},
    firmware_name: "",
    interface: nil,
    serial: nil
  }

  def start_link(port, opts \\ [], name \\ nil) do
    opts = Keyword.put(opts, :interface, self)
    GenServer.start_link(__MODULE__, {port, opts}, name: name)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def report_analog_channel(board, channel, value) do
    GenServer.call(board, {:report_analog_channel, channel, value})
  end

  def set_pin_mode(board, pin, mode) do
    GenServer.call(board, {:set_pin_mode, pin, mode})
  end

  def pin_state(board, pin) do
    board |> sysex_write(@pin_state_query, <<pin>>)
  end

  def digital_write(board, pin, value) do
    GenServer.call(board, {:digital_write, pin, value})
  end

  def sonar_config(board, trigger, echo, max_distance, ping_interval) do
    set_pin_mode(board, trigger, @sonar)
    set_pin_mode(board, echo, @sonar)
    max_distance_lsb = max_distance &&& 0x7f
    max_distance_msb = (max_distance >>> 7) &&& 0x7f
    data = <<trigger, echo, max_distance_lsb, max_distance_msb, ping_interval>>
    board |> sysex_write(@sonar_config, data)
  end

  def neopixel_register(board, pin, num_pixels) do
    data = <<pin, num_pixels>>
    board |> sysex_write(@neopixel_register, data)
  end

  def neopixel(board, index, {r, g, b}) do
    data = <<index, r, g, b>>
    board |> sysex_write(@neopixel, data)
  end

  def neopixel_brightness(board, brightness) do
    data = <<brightness>>
    board |> sysex_write(@neopixel_brightness, data)
  end

  def sysex_write(board, cmd, data) do
    GenServer.call(board, {:sysex_write, cmd, data})
  end

  ## Server Callbacks

  def init({port, opts}) do
    speed = opts[:speed] || 57600
    uart_opts = [speed: speed, active: true]

    {:ok, serial} = Nerves.UART.start_link
    :ok = Nerves.UART.open(serial, port, uart_opts)

    Nerves.UART.write(serial, <<0xFF>>)
    Nerves.UART.write(serial, <<0xF9>>)

    state =
      @initial_state
      |> Map.put(:serial, serial)
      |> Map.put(:interface, opts[:interface])
    {:ok, state}
  end

  def handle_call(:stop, _from, state) do
    Process.exit(state[:processor_pid], :normal)
    {:reply, :ok, state}
  end

  def handle_call({:report_analog_channel, channel, value}, {interface, _}, state) do
    state = state
    |> put_analog_channel(channel, :report, value)
    |> put_analog_channel(channel, :interface, interface)
    send_data(state, <<@report_analog ||| channel, value>>)
    {:reply, :ok, state}
  end

  def handle_call({:set_pin_mode, pin, mode}, _from, state) do
    state = state |> put_pin(pin, :mode, mode)
    send_data(state, <<@pin_mode,pin,mode>>)
    {:reply, :ok, state}
  end

  def handle_call({:digital_write, pin, value}, _from, state) do
    state = state |> put_pin(pin, :value, value)
    signal = state[:pins] |> Firmata.Protocol.digital_write(pin, value)
    send_data(state, signal)
    {:reply, :ok, state}
  end

  def handle_call({:sysex_write, cmd, data}, _from, state) do
    send_data(state, <<@start_sysex, cmd>> <> data <> <<@end_sysex>>)
    {:reply, :ok, state}
  end

  def handle_info({:nerves_uart, _port, data}, state) do
    {outbox, parser} = Enum.reduce(data, {state.outbox, state.parser}, &Firmata.Protocol.parse(&2, &1))
    Enum.each(outbox, &send(self, &1))
    {:noreply, %{state | outbox: [], parser: parser}}
  end

  def handle_info({:report_version, major, minor}, state) do
    send_data(state, <<@start_sysex, @capability_query, @end_sysex>>)
    state = Map.put(state, :version, {major, minor})
    send_info(state, {:version, major, minor})
    {:noreply, state}
  end

  def handle_info({:firmware_name, name}, state) do
    state = Map.put(state, :firmware_name, name)
    send_info(state, {:firmware_name, state[:firmware_name]})
    {:noreply, state}
  end

  def handle_info({:capability_response, pins}, state) do
    state = Map.put(state, :pins, pins)
    send_data(state, <<@start_sysex, @analog_mapping_query, @end_sysex>>)
    {:noreply, state}
  end

  def handle_info({:analog_mapping_response, mapping}, state) do
    pins = state[:pins]
    |> Enum.zip(mapping)
    |> Enum.map(fn({pin, map})-> Keyword.merge(pin, map) end)
    |> Enum.map(fn pin -> Keyword.merge(pin, [interface: nil]) end)
    state = Map.put(state, :pins, pins)
    send_info(state, {:pin_map, state[:pins]})
    {:noreply, state}
  end

  def handle_info({:analog_read, channel, value }, state) do
    state = state |> put_analog_channel(channel, :value, value, fn(pin) ->
      send_info(state, {:analog_read, pin[:analog_channel], value}, pin[:interface])
    end)
    {:noreply, state}
  end

  def handle_info({:i2c_response, [value: value] }, state) do
    send_info(state, {:i2c_response, value})
    {:noreply, state}
  end

  def handle_info({:string_data, [value: value] }, state) do
    send_info(state, {:string_data, value |> parse_ascii})
    {:noreply, state}
  end

  def handle_info({:sonar_data, [value: value, pin: pin]}, state) do
    send_info(state, {:sonar_data, pin, value})
    {:noreply, state}
  end

  def handle_info({:pin_state, pin, mode, pin_state}, state) do
    send_info(state, {:pin_state, pin, mode, pin_state})
    {:noreply, state}
  end

  def handle_info(unknown, state) do
    Logger.error("Unknown message in #{__MODULE__}: #{inspect unknown}")
    {:noreply, state}
  end

  defp send_data(state, data), do: Nerves.UART.write(state.serial, data)
  defp send_info(state, info, interface \\ nil) do
    case interface do
      nil -> send_to(state[:interface], {:firmata, info})
      _ -> send_to(interface, {:firmata, info})
    end
  end
  defp send_to(interface, message), do: send(interface, message)
  defp put_pin(state, index, key, value, found_callback \\ nil) do
    pins = state[:pins] |> List.update_at(index, fn(pin) ->
      pin = Keyword.put(pin, key, value)
      if (found_callback), do: found_callback.(pin)
      pin
    end)
    state = Map.put(state, :pins, pins)
  end
  defp analog_channel_to_pin_index(state, channel) do
    Enum.find_index(state[:pins], fn(pin) ->
      pin[:analog_channel] === channel
    end)
  end
  defp put_analog_channel(state, channel, key, value, found_callback \\ nil) do
    pin = analog_channel_to_pin_index(state, channel)
    put_pin(state, pin, key, value, found_callback)
  end

  defp parse_ascii(data), do: for n <- data, n != <<0>>, into: "", do: n

end
