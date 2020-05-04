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

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :circuits_uart]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:circuits_uart, "~> 1.4"},
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
