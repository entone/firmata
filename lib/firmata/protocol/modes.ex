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
      @encoder 0x09
      @serial 0x0A
      @input_pullup 0x0B
      @ignore 0x7F

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
        @encoder,
        @serial,
        @input_pullup,
        @ignore
      ]

      def translate_mode(@input), do: {:input, @input}
      def translate_mode(@output), do: {:output, @output}
      def translate_mode(@analog), do: {:analog, @analog}
      def translate_mode(@pwm), do: {:pwm, @pwm}
      def translate_mode(@servo), do: {:servo, @servo}
      def translate_mode(@shift), do: {:shift, @shift}
      def translate_mode(@i2c), do: {:i2c, @i2c}
      def translate_mode(@onewire), do: {:onewire, @onewire}
      def translate_mode(@stepper), do: {:stepper, @stepper}
      def translate_mode(@encoder), do: {:encoder, @encoder}
      def translate_mode(@serial), do: {:serial, @serial}
      def translate_mode(@input_pullup), do: {:input_pullup, @input_pullup}
      def translate_mode(@ignore), do: {:ignore, @ignore}
      def translate_mode(mode), do: {:unknown, mode}
    end
  end
end
