defmodule JobProcessingService.Job.Validator do
  @moduledoc """
  Validates the job payload to make sure the processing can be done later.
  """

  @schema %{
            "type" => "object",
            "required" => ["tasks"],
            "additionalProperties" => false,
            "properties" => %{
              "tasks" => %{
                "type" => "array",
                "items" => %{
                  "type" => "object",
                  "required" => ["name", "command"],
                  "additionalProperties" => false,
                  "properties" => %{
                    "name" => %{"type" => "string"},
                    "command" => %{"type" => "string"},
                    "requires" => %{
                      "type" => "array",
                      "items" => %{"type" => "string"}
                    }
                  }
                }
              }
            }
          }
          |> ExJsonSchema.Schema.resolve()

  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(payload) do
    with :ok <- ExJsonSchema.Validator.validate(@schema, payload),
         :ok <- validate_task_names(payload),
         :ok <- validate_required_tasks(payload),
         :ok <- validate_no_self_requirements(payload) do
      :ok
    else
      {:error, errors} when is_list(errors) -> {:error, format_errors(errors)}
      {:error, message} -> {:error, message}
    end
  end

  # No duplicated task names
  defp validate_task_names(%{"tasks" => tasks}) do
    names = Enum.map(tasks, & &1["name"])

    if length(names) == length(Enum.uniq(names)) do
      :ok
    else
      {:error, "Task names must be unique"}
    end
  end

  # No tasks that are "required" but don't exist in the main list
  defp validate_required_tasks(%{"tasks" => tasks}) do
    names = MapSet.new(tasks, & &1["name"])

    if Enum.all?(tasks, fn task ->
         task |> Map.get("requires", []) |> Enum.all?(&MapSet.member?(names, &1))
       end) do
      :ok
    else
      {:error, "Every task that is required by another one must exist in the payload"}
    end
  end

  # No task that requires itself
  defp validate_no_self_requirements(%{"tasks" => tasks}) do
    if Enum.all?(tasks, fn task -> task["name"] not in Map.get(task, "requires", []) end) do
      :ok
    else
      {:error, "A task cannot require itself"}
    end
  end

  defp format_errors(errors) do
    Enum.map_join(errors, "; ", fn {message, path} -> "#{path}: #{message}" end)
  end
end
