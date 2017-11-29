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
      @digital_message_range 0x90..0x9f
      # internal: fixnum byte command for an analog i/o message
      @analog_message 0xe0
      # internal: fixnum byte range for analog pins for analog 14-bit data format
      @analog_message_range 0xe0..0xef
      # internal: fixnum byte command to report analog pin
      @report_analog 0xc0
      # internal: fixnum byte command to report digital port
      @report_digital 0xd0
      # internal: fixnum byte command to set pin mode (i/o)
      @pin_mode  0xf4
      # internal: fixnum byte command for start of sysex message
      @start_sysex 0xf0
      # internal: fixnum byte command for end of sysex message
      @end_sysex 0xf7
      # internal: fixnum byte sysex command for capabilities query
      @capability_query 0x6b
      # internal: fixnum byte sysex command for capabilities response
      @capability_response 0x6c
      # internal: fixnum byte sysex command for pin state query
      @pin_state_query 0x6d
      # internal: fixnum byte sysex command for pin state response
      @pin_state_response 0x6e
      # internal: fixnum byte sysex command for analog mapping query
      @analog_mapping_query 0x69
      # internal: fixnum byte sysex command for analog mapping response
      @analog_mapping_response 0x6a
      # internal: fixnum byte sysex command for firmware query and response
      @firmware_query 0x79

      @i2c_config 0x78

      @i2c_request 0x76

      @i2c_response 0x77

      @i2c_mode %{write: 00, read: 10}

      @string_data 0x71

      # custom for sonar range sensors
      @sonar_config 0x62  # configure pins to control a Ping type sonar distance device
      @sonar_data 0x63  # distance data returned


      def to_hex(<<byte>>) do
        "0x"<>Integer.to_string(byte, 16)
      end
    end
  end
end
