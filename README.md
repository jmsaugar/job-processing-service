# JobProcessingService

A minimal HTTP service built with Plug and Cowboy.

## Run

```sh
mix deps.get
mix run --no-halt
```

The server listens on port 4000. In another terminal:

```sh
curl http://localhost:4000/job
```

`GET /job` returns HTTP 200 with `{"status":"ok"}`. This is a placeholder
endpoint; it does not process or store jobs yet. Other paths and methods return 404.

## Linting / static analysis
```sh
mix credo
mix dialyzer
```

## Test

```sh
mix test
```

Tests use an automatically assigned port to avoid conflicting with a running server.
