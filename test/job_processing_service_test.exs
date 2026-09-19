defmodule JobProcessingServiceTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias JobProcessingService.Router

  @opts Router.init([])

  test "POST /job returns a JSON response" do
    payload = %{"tasks" => [%{"name" => "task-1", "command" => "echo ok"}]}
    conn = post_json("/job?format=json", payload)

    assert conn.status == 200
    # TODO to be updated later
    assert Jason.decode!(conn.resp_body) == %{"tasks" => []}
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  test "POST /job returns a BASH response" do
    payload = %{"tasks" => [%{"name" => "task-1", "command" => "echo ok"}]}
    conn = post_json("/job?format=bash", payload)

    assert conn.status == 200
    # TODO to be updated later
    assert conn.resp_body == "script"

    assert Plug.Conn.get_resp_header(conn, "content-type") == [
             "text/x-shellscript; charset=utf-8"
           ]
  end

  test "POST /job rejects a payload that does not match the JSON schema" do
    payload = %{"tasks" => [%{"name" => "task-1"}]}
    conn = post_json("/job?format=json", payload)

    assert conn.status == 400
    assert %{"error" => _message} = Jason.decode!(conn.resp_body)
  end

  test "POST /job rejects a required task missing from the tasks list" do
    payload = %{
      "tasks" => [
        %{"name" => "task-1", "command" => "echo ok", "requires" => ["missing-task"]}
      ]
    }

    conn = post_json("/job?format=json", payload)

    assert conn.status == 400

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "Every task that is required by another one must exist in the payload"
           }
  end

  test "POST /job rejects duplicated task names" do
    payload = %{
      "tasks" => [
        %{"name" => "task-1", "command" => "echo first"},
        %{"name" => "task-1", "command" => "echo second"}
      ]
    }

    conn = post_json("/job?format=json", payload)

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body) == %{"error" => "Task names must be unique"}
  end

  test "unknown routes return 404" do
    conn = Router.call(conn(:get, "/unknown"), @opts)

    assert conn.status == 404
  end

  test "unsupported methods return 404" do
    conn = Router.call(conn(:get, "/job"), @opts)

    assert conn.status == 404
  end

  defp post_json(path, payload) do
    conn(:post, path, Jason.encode!(payload))
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Router.call(@opts)
  end
end
