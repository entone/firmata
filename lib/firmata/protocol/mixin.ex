defmodule Firmata.Protocol.Mixin do
  defmacro __using__(_) do
    quote location: :keep do
      use Bitwise
      use Firmata.Protocol.Modes

      # Internal: Fixnum byte command for protocol version
      @report_version 0xF9
      # Internal: Fixnum byte command for system reset
      @system_reset 0xFF
      # Internal: Fixnum byte command for digital I/O message
      @digital_message 0x90
      # Pubilc: Fixnum byte for range for digital pins for digital 2 byte data format
      @digital_message_range 0x90..0x9F
      # internal: fixnum byte command for an analog i/o message
      @analog_message 0xE0
      # internal: fixnum byte range for analog pins for analog 14-bit data format
      @analog_message_range 0xE0..0xEF
      # internal: fixnum byte command to report analog pin
      @report_analog 0xC0
      # internal: fixnum byte command to report digital port
      @report_digital 0xD0
      # internal: fixnum byte command to set pin mode (i/o)
      @pin_mode 0xF4
      # internal: fixnum byte command for start of sysex message
      @start_sysex 0xF0
      # internal: fixnum byte command for end of sysex message
      @end_sysex 0xF7
      # internal: fixnum byte sysex command for capabilities query
      @capability_query 0x6B
      # internal: fixnum byte sysex command for capabilities response
      @capability_response 0x6C
      # internal: fixnum byte sysex command for pin state query
      @pin_state_query 0x6D
      # internal: fixnum byte sysex command for pin state response
      @pin_state_response 0x6E
      # internal: fixnum byte sysex command for analog mapping query
      @analog_mapping_query 0x69
      # internal: fixnum byte sysex command for analog mapping response
      @analog_mapping_response 0x6A
      # internal: fixnum byte sysex command for firmware query and response
      @firmware_query 0x79

      @i2c_config 0x78

      @i2c_request 0x76

      @i2c_response 0x77

      @i2c_mode %{write: 00, read: 10}

      @string_data 0x71

      # custom for sonar range sensors
      # configure pins to control a Ping type sonar distance device
      @sonar_config 0x62
      # distance data returned
      @sonar_data 0x63

      # custom for neopixels
      # arg0 pin_number, arg1 num_pixels
      @neopixel_register 0x74
      # arg0 brightness
      @neopixel_brightness 0x73
      # arg0 pixel_index, arg1 red, arg2 green, arg3 blue
      @neopixel 0x72

      def to_hex(<<byte>>) do
        "0x" <> Integer.to_string(byte, 16)
      end
    end
  end
end
