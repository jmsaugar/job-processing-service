defmodule JobProcessingServiceTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias JobProcessingService.Router

  @opts Router.init([])

  # TODO to be updated later
  test "POST /job returns a JSON response" do
    conn = Router.call(conn(:post, "/job"), @opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"status" => "ok"}
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  test "unknown routes return 404" do
    conn = Router.call(conn(:get, "/unknown"), @opts)

    assert conn.status == 404
  end

  test "unsupported methods return 404" do
    conn = Router.call(conn(:get, "/job"), @opts)

    assert conn.status == 404
  end
end
