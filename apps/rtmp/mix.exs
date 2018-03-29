defmodule Rtmp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rtmp,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description()
     ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    environment_specific_deps(Mix.env) ++ [
      {:ex_doc, ">= 0.0.0", only: [:dev, :umbrella]}
    ]
  end

  defp environment_specific_deps(_), do: [{:amf0, in_umbrella: true}]

  defp package do
    [
      name: :eml_rtmp,
      maintainers: ["Matthew Shapiro"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KallDrexx/elixir-media-libs/tree/master/apps/rtmp"}
    ]
  end

  defp description do
    "Library containing functionality for handling RTMP connections, from handshaking, " <>
    "serialization, deserialization, and logical flow of RTMP data."
  end
end
