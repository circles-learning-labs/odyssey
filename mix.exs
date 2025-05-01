defmodule Odyssey.MixProject do
  use Mix.Project

  @github_url "https://github.com/circles-learning-labs/odyssey"

  def project do
    [
      app: :odyssey,
      description: "A workflow engine for Elixir",
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      source_url: @github_url,
      package: package()
    ]
  end

  def package do
    [
      name: "odyssey",
      licenses: ["MIT"],
      maintainers: ["Bernard Duggan"],
      links: %{
        "GitHub" => @github_url
      },
      exclude_patterns: [~r/.*~/, ~r/src\/.*\.erl/]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:eventually, "~> 1.1", only: :test, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:igniter, "~> 0.5", only: [:dev], runtime: false},
      {:oban, "~> 2.19"},
      {:postgrex, "~> 0.20"}
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
