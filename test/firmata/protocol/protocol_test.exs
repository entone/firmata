defmodule Firmata.Protocol.ProtocolTest do
  use FirmataTest.Mixin

  import Firmata.Protocol, only: [digital_write: 3]

  doctest Firmata

  test "(all pins low) digital write pin 10 from low to high" do
    data = @low_pins |> low(10) |> digital_write(10, @high)
    assert data == <<145, 0, 0>>
  end

  test "(all pins low) digital write pin 10 from high to low" do
    data = @low_pins |> high(10) |> digital_write(10, @low)
    assert data == <<145, 4, 0>>
  end

  test "(all pins low) digital write pin 13 from low to high" do
    data = @low_pins |> low(13) |> digital_write(13, @high)
    assert data == <<145, 0, 0>>
  end

  test "(all pins low) digital write pin 13 from high to low" do
    data = @low_pins |> high(13) |> digital_write(13, @low)
    assert data == <<145, 32, 0>>
  end

  test "(all pins high) digital write pin 10 from low to high" do
    data = @high_pins |> low(10) |> digital_write(10, @high)
    assert data == <<145, 123, 3>>
  end

  test "(all pins high) digital write pin 10 from high to low" do
    data = @high_pins |> high(10) |> digital_write(10, @low)
    assert data == <<145, 127, 3>>
  end

  test "(all pins high) digital write pin 13 from low to high" do
    data = @high_pins |> low(13) |> digital_write(13, @high)
    assert data == <<145, 95, 3>>
  end

  test "(all pins high) digital write pin 13 from high to low" do
    data = @high_pins |> high(13) |> digital_write(13, @low)
    assert data == <<145, 127, 3>>
  end
end
