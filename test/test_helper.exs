defmodule FirmataTest.Helper do
  defmacro __using__(_) do
    quote location: :keep do
      use Firmata.Protocol.Mixin
      @low_pins 1..20 |> Enum.map(fn _ -> [value: 0] end)
      @high_pins 1..20 |> Enum.map(fn _ -> [value: 1] end)
      @high 1
      @low 0

      defp high(pins, index), do: set_pin(pins, index, @high)
      defp low(pins, index), do: set_pin(pins, index, @low)

      defp set_pin(pins, index, value) do
        List.update_at(pins, index, fn pin ->
          Keyword.put(pin, :value, value)
        end)
      end
    end
  end
end

ExUnit.start()
