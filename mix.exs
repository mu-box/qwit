defmodule QWIT.MixProject do
  use Mix.Project

  def project do
    [
      app: :qwit,
      version: "0.1.0",
      description: "A library for building workflows out of queued worker jobs, and running them as transactions.",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      name: "QWIT",
      source_url: "https://github.com/mu-box/qwit",
      docs: [
        main: "readme", # The main page in the docs
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22.0", only: :dev, runtime: false},
      {:oban, "~> 2.1", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Dan Hunsaker", "Microbox Team"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mu-box/qwit"}
    ]
  end
end
