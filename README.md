# Crafting Software Coding Challenge

## Technology

This challenge has been solved using:

- Elixir 1.20.4 (compiled with Erlang/OTP 29)
- Credo (1.7) and Dialyxir (1.4) for static checking.
- Plug_cowboy (2.9) for the server.
- Jason (1.4) for JSON manipulation
- Ex_json_schema for JSON validation.

## How to run the project

Clone the repository, checkout to the `main` branch and run:

```sh
mix deps.get
mix start
```

`mix start` runs the service on port 4000 by default and keeps it running. To choose another port:

```sh
mix start --port 4001
```

## Endpoints specs

The service only exposes a single `/job` endpoint using HTTP `POST`, which expects a JSON payload as per the challenge specifications.

### `/job` options

There are 2 ways to modify the behaviour of this endpoint:

#### `format` query param

- `json` (default value): returns the output in JSON format as per the challenge specs.
- `bash`: returns the output as a bash script string as per the challenge specs.

#### `algorithm` query param

- `manual`: performs the task using a manual implementation of the tasks sorting algorithm.
- `builtin`: performs the task using the Erlang Standard Library digraph utilities.

Refer to the `Why two implementations of the solution` section for more details on this.

## Manual testing

The service can be tested manually using curl requests.

The specifications of the service are:

Example using the same tasks as in the challenge definition:

```sh
curl -i -X POST 'http://localhost:4000/job?format=json&algorithm=manual' \
  -H 'Content-Type: application/json' \
  -d '{
    "tasks": [
      {"name": "task-1", "command": "touch /tmp/file1"},
      {"name": "task-2", "command": "cat /tmp/file1", "requires": ["task-3"]},
      {"name": "task-3", "command": "echo \"Hello World!\" > /tmp/file1", "requires": ["task-1"]},
      {"name": "task-4", "command": "rm /tmp/file1", "requires": ["task-2", "task-3"]}
    ]
  }'
```

## Linting / static analysis

```sh
mix credo
mix dialyzer
```

## Unit testing

Added 2 test batteries, that cover different aspects of the solution:

### `job_processing_service_test.exs`

Tests the HTTP service end to end behaviour, including payload validation, correct output format, etc.

### `processor_test.exs`

Tests the actual job tasks processing logic, both for the manual and the built in solutions.

```sh
mix test
```

## Solution overview

The solution establishes a very simple HTTP server using `cowboy` and sets up a router with the single `/job` endpoint.

The router is configured to parse JSON payloads and the single endpoint reads the 2 optional query params and processes the input, performing first a validation, which is implemented in the `JobProcessingService.Job.Validator` module.

### Input validation

This validation uses `ex_json_schema` to make sure the shape of the data is compliant with the specs and performs some extra checks to make sure the processing step can run without issues (e.g. no duplicated taks names, required task must exist, a task can not require itself).

If validation succeeds, the `JobProcessingService.Job.Processor` module is invoked to start the actual processing.

### Processing

#### Why two implementations of the solution

The problem stated in the challenge is the topological sorting of the tasks based on their dependencies.

Being this a coding challenge, it was my understanding that a "manual" implementation of this was what was intended, so I implemented it in the `JobProcessingService.Job.ProcessorManual` module using Depth First Search.

Doing some more research afterwards, I found that Erlang Standard Library provides an utility to solve this problem (digraph)[https://www.erlang.org/doc/apps/stdlib/digraph.html] so I added that implementation too.

The rationale is that, in a production solution, I would have probably used that one, but as this is a test, I included both to account for the fact that: 1) I can implement it manually if necessary and 2) I can leverage the ecosystem provided features as that's valuable in a real project.

### Output

There is a dedicated module (`JobProcessingService.Job.Output`) to create the output of the processing. This was done to have a clearer separation of concerns (validation vs processing vs output generation).

The output module generates the output in JSON or BASH format, and it also takes care of the error message construction in the case cycles are detected during the processing.

### Other considerations

Being this a test, I made the assumption and I have omitted other features that obviously should be present in a real production web service (logging and observability, authentication, better architecture/modularization in case of a bigger set of endpoints and functionality, etc).
