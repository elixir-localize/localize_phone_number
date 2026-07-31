defmodule Localize.PhoneNumber.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :localize_phone_number,
      version: @version,
      name: "Localize.PhoneNumber",
      source_url: "https://github.com/elixir-localize/localize_phone_number",
      docs: docs(),
      description: description(),
      package: package(),
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_makefile: "c_src/Makefile",
      deps: deps(),
      dialyzer: [
        flags: [
          :error_handling,
          :unknown,
          :underspecs,
          :extra_return,
          :missing_return
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Phone number parsing, formatting, and validation via Google's libphonenumber. " <>
      "Locale-aware territory defaults powered by Localize."
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "c_src/Makefile",
        "c_src/localize_phone_number_nif.cpp",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  defp links do
    %{
      "GitHub" => "https://github.com/elixir-localize/localize_phone_number",
      "Readme" =>
        "https://github.com/elixir-localize/localize_phone_number/blob/v#{@version}/README.md",
      "Changelog" =>
        "https://github.com/elixir-localize/localize_phone_number/blob/v#{@version}/CHANGELOG.md"
    }
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras:
        [
          "README.md",
          "LICENSE.md",
          "CHANGELOG.md"
        ] ++ Path.wildcard("guides/*.md"),
      formatters: ["html", "markdown"],
      groups_for_extras: [
        Guides: Path.wildcard("guides/*.md")
      ],
      skip_undefined_reference_warnings_on:
        [
          "CHANGELOG.md"
        ] ++ Path.wildcard("guides/*.md")
    ]
  end

  defp deps do
    [
      {:localize, "~> 1.0"},
      {:elixir_make, "~> 0.4", runtime: false},
      {:ecto, "~> 3.12", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:phoenix_html, "~> 4.0", optional: true},
      {:ex_doc, "~> 0.35", only: :release, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ] ++ maybe_json_polyfill()
  end

  defp maybe_json_polyfill do
    if Code.ensure_loaded?(:json) do
      []
    else
      [{:json_polyfill, "~> 0.2 or ~> 1.0"}]
    end
  end
end
