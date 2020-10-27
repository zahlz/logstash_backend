defmodule LogstashBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :logstash_backend,
     name: "logstash_backend",
     source_url: "https://github.com/zahlz/logstash_backend",
     version: "5.0.0",
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :timex, :tzdata, :jason]]
  end

  defp deps do
    [
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.23", only: :dev},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.6"}
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
