defmodule Firmata.Protocol.Modes do
  defmacro __using__(_) do
    quote location: :keep do
      @input 0x00
      @output 0x01
      @analog 0x02
      @pwm 0x03
      @servo 0x04
      @shift 0x05
      @i2c 0x06
      @onewire 0x07
      @stepper 0x08
      @serial 0x0A
      @ignore 0x7F
      @ping_read 0x75
      @sonar 0x0B
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
        @sonar,
        @unknown
      ]
    end
  end
end
