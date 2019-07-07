defmodule Firmata.Protocol.Sysex.SysexTest do
  use ExUnit.Case, async: true
  use FirmataTest.Helper

  import Firmata.Protocol.Sysex, only: [capability_response: 1]

  doctest Firmata.Protocol.Sysex

  @sysex <<127, 127, 0, 1, 11, 1, 1, 1, 4, 14, 127, 0, 1, 11, 1, 1, 1, 3, 8, 4, 14, 127, 0, 1, 11,
           1, 1, 1, 4, 14, 127, 0, 1, 11, 1, 1, 1, 3, 8, 4, 14, 127, 0, 1, 11, 1, 1, 1, 3, 8, 4,
           14, 127, 0, 1, 11, 1, 1, 1, 4, 14, 127, 0, 1, 11, 1, 1, 1, 4, 14, 127, 0, 1, 11, 1, 1,
           1, 3, 8, 4, 14, 127, 0, 1, 11, 1, 1, 1, 3, 8, 4, 14, 127, 0, 1, 11, 1, 1, 1, 3, 8, 4,
           14, 127, 0, 1, 11, 1, 1, 1, 4, 14, 127, 0, 1, 11, 1, 1, 1, 4, 14, 127, 0, 1, 11, 1, 1,
           1, 2, 10, 4, 14, 127, 0, 1, 11, 1, 1, 1, 2, 10, 4, 14, 127, 0, 1, 11, 1, 1, 1, 2, 10,
           4, 14, 127, 0, 1, 11, 1, 1, 1, 2, 10, 4, 14, 127, 0, 1, 11, 1, 1, 1, 2, 10, 4, 14, 6,
           1, 127, 0, 1, 11, 1, 1, 1, 2, 10, 4, 14, 6, 1, 127>>

  @pins [
    [supported_modes: [6, 4, 2, 1, 0], mode: 16],
    [supported_modes: [6, 4, 2, 1, 0], mode: 16],
    [supported_modes: [4, 2, 1, 0], mode: 16],
    [supported_modes: [4, 2, 1, 0], mode: 16],
    [supported_modes: [4, 2, 1, 0], mode: 16],
    [supported_modes: [4, 2, 1, 0], mode: 16],
    [supported_modes: [4, 1, 0], mode: 16],
    [supported_modes: [4, 1, 0], mode: 16],
    [supported_modes: [4, 3, 1, 0], mode: 16],
    [supported_modes: [4, 3, 1, 0], mode: 16],
    [supported_modes: [4, 3, 1, 0], mode: 16],
    [supported_modes: [4, 1, 0], mode: 16],
    [supported_modes: [4, 1, 0], mode: 16],
    [supported_modes: [4, 3, 1, 0], mode: 16],
    [supported_modes: [4, 3, 1, 0], mode: 16],
    [supported_modes: [4, 1, 0], mode: 16],
    [supported_modes: [4, 3, 1, 0], mode: 16],
    [supported_modes: [4, 1, 0], mode: 16],
    [supported_modes: [], mode: 16],
    [supported_modes: [], mode: 16]
  ]

  test "compatibility_response" do
    assert capability_response(@sysex)[:pins] == @pins
  end
end
