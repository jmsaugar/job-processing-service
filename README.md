# JobProcessingService

A minimal HTTP service built with Plug and Cowboy.

## Run

```sh
mix deps.get
mix run --no-halt
```

### Manual testing

The service can be tested manually using curl requests.

The specifications of the service are:

- Endpoints: POST `/job/`
- Payload: as per project specs:
```json
{
  "tasks": [
    {
      "name": "The task name",
      "command": "echo 'the task bash command'",
      "requires": ["optional", "list", "of", "task", "names", "dependencies"]
    },
    ...
  ]
}
```
- Output: the output can be set via the `output` query param, which accepts `json` or `bash` and sends content-type HTTP header accordingly.

```sh
curl -i -X POST 'http://localhost:4000/job?format=json' \
  -H 'Content-Type: application/json' \
  -d '{
    "tasks": [
      {"name": "A", "command": "touch A", "requires": ["B"]},
      {"name": "B", "command": "touch B", "requires": ["C"]},
      {"name": "C", "command": "touch C", "requires": ["A"]}
    ]
  }'
```

## Linting / static analysis
```sh
mix credo
mix dialyzer
```

## Unit testing

```sh
mix test
```

Tests use an automatically assigned port to avoid conflicting with a running server.
