defmodule JobProcessingService.Router do
  @moduledoc """
  Routes HTTP requests to the job endpoint.
  """
  use Plug.Router
  use Plug.ErrorHandler

  alias JobProcessingService.Job

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  post "/job" do
    conn = fetch_query_params(conn)

    with {:ok, format} <- output_format(conn.query_params),
         {:ok, algorithm} <- selected_algo(conn.query_params),
         :ok <- Job.Validator.validate(conn.body_params),
         {:ok, output} <- Job.Processor.process(conn.body_params, format, algorithm) do
      case format do
        :json -> json(conn, 200, output)
        :bash -> bash(conn, 200, output)
      end
    else
      # Query parameter error
      {:error, :query, message} -> json(conn, 400, %{error: message})
      # Processing errors found by processing (e.g. cycles) already formatted by Output.
      {:error, %{error: _} = output} -> json(conn, 422, output)
      # Validation errors.
      {:error, message} -> json(conn, 400, %{error: message})
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{reason: reason} = _data) do
    json(conn, conn.status, %{error: Exception.message(reason)})
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

  defp selected_algo(params) do
    case Map.get(params, "algorithm", "manual") do
      "manual" -> {:ok, :manual}
      "builtin" -> {:ok, :builtin}
      _ -> {:error, :query, "selected_algo must be manual or builtin"}
    end
  end
end
