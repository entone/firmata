defmodule Firmata.Board do
  use GenServer

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

  def pin_mode(board, pin, mode) do
    #write(PIN_MODE, 
  end

  ## Server Callbacks

  def init([tty, baudrate]) do
    IO.puts "Init'd with tty #{tty} @ #{baudrate}"
    {:ok, serial} = Serial.start_link
    Serial.open(serial, tty)
    Serial.set_speed(serial, baudrate)
    state = [
      serial: serial,
      connected: false
    ]
    {:ok, state}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Keyword.get(state, key), state}
  end

  def handle_call(:connect, _from, state) do
    Keyword.get(state, :serial) |> Serial.connect
    {:reply, :ok, state}
  end

  def handle_info({:elixir_serial, _serial, data}, state) do
    acc = Firmata.Protocol.Accumulator.unpack(state)
    state = Enum.scan(data, acc, &Firmata.Protocol.parse(&2, &1))
    |> List.last
    |> Firmata.Protocol.Accumulator.pack
    {:noreply, state}
  end
end
