defmodule Firmata.Writer do
  use GenServer
  require Logger
  alias Nerves.UART, as: Serial

  @packet_length Application.get_env(:firmata, :packet_length) || 24
  @packet_rate Application.get_env(:firmata, :packet_rate) || 5

  defmodule State do
    defstruct [
      :interface,
      messages: [],
    ]
  end

  def write(data) do
    GenServer.call(__MODULE__, {:write, data})
  end

  def set_serial_interface(interface) do
    GenServer.call(__MODULE__, {:add_interface, interface})
  end

  def start_link(interface) do
    GenServer.start_link(__MODULE__, {:interface, interface}, name: __MODULE__)
  end

  def init({:interface, interface}) do
    Process.send_after(self(), :handle_messages, 0)
    Process.send_after(self(), :health_check, 1000)
    {:ok, %State{interface: interface}}
  end

  def handle_call({:add_interface, interface}, _from, state) do
    {:reply, interface, %State{state | interface: interface}}
  end

  def handle_call({:write, data}, _from, state) do
    {:reply, data, %State{state | messages: state.messages ++ [{:data, data}]}}
  end

  def handle_info(:health_check, %State{messages: messages} = state ) do
    Logger.info "Message Queue: #{Enum.count(messages)}"
    Process.send_after(self(), :health_check, 1000)
    {:noreply, state}
  end

  def handle_info(:handle_messages, %State{messages: []} = state) do
    Process.send_after(self(), :handle_messages, @packet_rate)
    {:noreply, state}
  end

  def handle_info(:handle_messages, %State{messages: messages} = state) do
    {packet, new_messages} = messages |> build_packet
    Serial.write(state.interface, packet)
    Process.send_after(self(), :handle_messages, @packet_rate)
    {:noreply, %State{state | messages: new_messages}}
  end

  defp build_packet([], packet), do: {packet, []}
  defp build_packet([{:data, data} | t] = messages, packet \\ "") do
    case packet <> data do
      p when byte_size(p) < @packet_length -> build_packet(t, p)
      _ignore -> {packet, messages}
    end
  end

end
