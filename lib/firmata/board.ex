defmodule Firmata.Board do
  use GenServer
  use Firmata.Protocol.Mixin

  @doc """
  {:ok, board} = Firmata.Board.start_link "/dev/cu.usbmodem1421"
  """
  def start_link(tty, baudrate) do
    GenServer.start_link(__MODULE__, [tty, baudrate], [])
  end

  def connect(board) do
    GenServer.call(board, :connect, 10000)
    block_until_connected(board)
    :ok
  end

  defp block_until_connected(board) do
    unless connected?(board), do: block_until_connected(board)
  end

  def connected?(board) do
    get(board, :connected)
  end

  def get(board, key) do
    GenServer.call(board, {:get, key})
  end

  ## Server Callbacks

  def init([tty, baudrate]) do
    {:ok, serial} = Serial.start_link
    Serial.open(serial, tty)
    Serial.set_speed(serial, baudrate)
    state = [ serial: serial, connected: false ]
    {:ok, state}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Keyword.get(state, key), state}
  end

  def handle_call(:connect, _from, state) do
    Keyword.get(state, :serial) |> Serial.connect
    {:reply, :ok, state}
  end

  def handle_info(:report_version, state) do
    Serial.send_data(state[:serial], <<@start_sysex, @capability_query, @end_sysex>>)
    {:noreply, state}
  end

  def handle_info({:major_version, major }, state) do
    {:noreply, Keyword.put(state, :major_version, major)}
  end

  def handle_info({:minor_version, minor }, state) do
    {:noreply, Keyword.put(state, :minor_version, minor)}
  end

  def handle_info({:firmware_name, name }, state) do
    {:noreply, Keyword.put(state, :firmware_name, name)}
  end

  def handle_info({:pins, pins }, state) do
    IO.inspect pins
    {:noreply, Keyword.put(state, :pins, pins)}
  end

  def handle_info({:elixir_serial, _serial, data}, state) do
    acc = Firmata.Protocol.Accumulator.unpack(state)
    state = Enum.reduce(data, acc, &Firmata.Protocol.parse(&2, &1))
    |> Firmata.Protocol.Accumulator.pack(state)
    {:noreply, state}
  end
end
