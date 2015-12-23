defmodule Firmata.Board do
  use GenServer
  use Firmata.Protocol.Mixin

  @initial_state [
    pins: [],
    outbox: [],
    parser: {},
    firmware_name: "",
    interface: nil,
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, self, opts)
  end

  def get(board, key) do
    GenServer.call(board, {:get, key})
  end

  def set(board, key, value) do
    GenServer.call(board, {:set, key, value})
  end

  def report_analog_channel(board, channel, value) do
    GenServer.call(board, {:report_analog_channel, channel, value})
  end

  def set_pin_mode(board, pin, mode) do
    GenServer.call(board, {:set_pin_mode, pin, mode})
  end

  def digital_write(board, pin, value) do
    GenServer.call(board, {:digital_write, pin, value})
  end

  ## Server Callbacks

  def init(interface) do
    board = self
    spawn_link(fn()-> process_outbox(board) end)
    {:ok, @initial_state |> Keyword.put(:interface, interface)}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Keyword.get(state, key), state}
  end

  def handle_call({:set, key, value}, _from, state) do
    {:reply, :ok, Keyword.put(state, key, value)}
  end

  def handle_call({:report_analog_channel, channel, value}, _from, state) do
    state = state |> put_analog_channel(channel, :report, value)
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

  def handle_info({:report_version, major, minor }, state) do
    send_data(state, <<@start_sysex, @capability_query, @end_sysex>>)
    state = Keyword.put(state, :version, {major, minor})
    send_info(state, {:version, major, minor})
    {:noreply, state}
  end

  def handle_info({:firmware_name, name }, state) do
    state = Keyword.put(state, :firmware_name, name)
    send_info(state, {:firmware_name, state[:firmware_name]})
    {:noreply, state}
  end

  def handle_info({:capability_response, pins }, state) do
    state = Keyword.put(state, :pins, pins)
    send_data(state, <<@start_sysex, @analog_mapping_query, @end_sysex>>)
    {:noreply, state}
  end

  def handle_info({:analog_mapping_response, mapping }, state) do
    pins = Enum.zip(state[:pins], mapping)
    |> Enum.map(fn({pin, map})-> Keyword.merge(pin, map) end)
    state = Keyword.put(state, :pins, pins)
    send_info(state, {:pin_map, state[:pins]})
    {:noreply, state}
  end

  def handle_info({:analog_read, channel, value }, state) do
    state = state |> put_analog_channel(channel, :value, value, fn(pin) ->
      send_info(state, {:analog_read, pin[:analog_channel], value})
    end)
    {:noreply, state}
  end

  def handle_info({:serial, data}, state) do
    acc = Firmata.Protocol.State.unpack(state)
    acc = Enum.reduce(data, acc, &Firmata.Protocol.parse(&2, &1))
    state = Firmata.Protocol.State.pack(acc, state)
    {:noreply, state}
  end

  defp send_data(state, data), do: send_to(state[:interface], {:send_data, data})
  defp send_info(state, info), do: send_to(state[:interface], info)
  defp send_to(pid, message), do: send(pid, {:firmata, message})
  defp put_pin(state, index, key, value, found_callback \\ nil) do
    pins = state[:pins] |> List.update_at(index, fn(pin) ->
      pin = Keyword.put(pin, key, value)
      if (found_callback), do: found_callback.(pin)
      pin
    end)
    state = Keyword.put(state, :pins, pins)
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
  defp process_outbox(board) do
    outbox = get(board, :outbox)
    if Enum.count(outbox) > 0 do
      [message | tail] = outbox
      set(board, :outbox, tail)
      send(board, message)
    end
    process_outbox(board)
  end
end
