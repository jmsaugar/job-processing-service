defmodule JobProcessingService.MixProject do
  use Mix.Project

  def project do
    [
      app: :job_processing_service,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      aliases: [start: &start/1],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {JobProcessingService.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp start(args) do
    case OptionParser.parse(args, strict: [port: :integer]) do
      {[], [], []} ->
        :ok

      {[port: port], [], []} when port in 1..65_535 ->
        Mix.Task.run("app.config")
        Application.put_env(:job_processing_service, :port, port)

      _ ->
        Mix.raise("Usage: mix start [--port PORT], where PORT is an integer from 1 to 65535")
    end

    Mix.Task.run("run", ["--no-halt"])
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.9"},
      {:jason, "~> 1.4"},
      {:ex_json_schema, "~> 0.11.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
