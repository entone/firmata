defmodule Firmata.Mixfile do
  use Mix.Project

  def project do
    [
      app: :firmata,
      version: "0.0.2",
      elixir: "~> 1.1",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :nerves_uart]]
  end

  defp deps do
    [
      {:nerves_uart, "~> 0.1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    This package implements the Firmata protocol.

    Firmata is a MIDI-based protocol for communicating with microcontrollers.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Keyvan Fatehi", "Christopher Coté"],
      licenses: ["ISC"],
      links: %{
        "GitHub" => "https://github.com/entone/firmata",
        "Firmata Protocol" => "https://github.com/firmata/protocol"
      }
    ]
  end
end
