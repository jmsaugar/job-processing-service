defmodule JobProcessingService.Router do
  @moduledoc """
  Routes HTTP requests to the job endpoint.
  """
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/job" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok"}))
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
