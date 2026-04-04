defmodule Localize.PhoneNumber.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :localize_phone_number,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_makefile: "c_src/Makefile",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:localize, path: "../localize"},
      {:elixir_make, "~> 0.4", runtime: false}
    ]
  end
end
