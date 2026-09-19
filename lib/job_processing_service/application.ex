defmodule JobProcessingService.Application do
  @moduledoc """
  Starts the HTTP server under the application supervisor.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: JobProcessingService.Router,
       options: [port: Application.get_env(:job_processing_service, :port, 4000)]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: JobProcessingService.Supervisor)
  end
end
