defmodule JobProcessingService.Router do
  @moduledoc """
  Routes HTTP requests to the job endpoint.
  """
  use Plug.Router

  alias JobProcessingService.Job

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  post "/job" do
    conn = fetch_query_params(conn)

    with {:ok, format} <- output_format(conn.query_params),
         :ok <- Job.Validator.validate(conn.body_params),
         {:ok, output} <- Job.Processor.process(conn.body_params, format) do
      case format do
        :json -> json(conn, 200, output)
        :bash -> bash(conn, 200, output)
      end
    else
      # Query parameter error
      {:error, :query, message} -> json(conn, 400, %{error: message})
      # Validation errors.
      {:error, message} -> json(conn, 400, %{error: message})
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  defp bash(conn, status, body) do
    conn
    |> put_resp_content_type("text/x-shellscript")
    |> send_resp(status, body)
  end

  defp output_format(params) do
    case Map.get(params, "format", "json") do
      "json" -> {:ok, :json}
      "bash" -> {:ok, :bash}
      _ -> {:error, :query, "format must be json or bash"}
    end
  end
end
