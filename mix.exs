defmodule LogstashBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logstash_backend,
      name: "logstash_backend",
      source_url: "https://github.com/zahlz/logstash_backend",
      version: "5.0.0",
      elixir: "~> 1.3",
      test_paths: ["test"],
      test_pattern: "**/*_test.exs",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :timex, :tzdata, :jason]]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:timex, "~> 3.6"},

      # Documentation
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.23", only: :dev},

      # Linting
      {:credo, "~> 1.4", only: [:dev, :test], override: true},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 0.6", only: [:dev, :test], runtime: false},

      # Security check
      {:sobelow, "~> 0.10", only: [:dev, :test], runtime: true},
      {:mix_audit, "~> 0.1", only: [:dev, :test], runtime: false},

      # Test coverage
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end

  defp description do
    """
    Logstash UDP producer backend for Logger.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Marcelo Gornstein"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/marcelog/logger_logstash_backend"
      }
    ]
  end
end
