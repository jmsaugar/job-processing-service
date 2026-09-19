defmodule JobProcessingService.Job.Processor do
  @moduledoc """
  Processes the job payload.
  """

  alias JobProcessingService.Job.Output

  # Input task has "name" and "command" as strings and optionally "requires" which is a string list
  @type task :: %{String.t() => String.t() | [String.t()]}

  @spec process(map(), :json | :bash) :: Output.result()
  def(process(body, format)) do
    body["tasks"] |> process_tasks() |> Output.new(format)
  end

  @spec process_tasks([task()]) ::
          {:ok, [task()]} | {:error, {:cyclic_dependencies, [String.t()]}}
  defp process_tasks(tasks) do
    process(
      # Restructure the data to be simpler and easier to operate in the algorithm
      # %{"A" => ["B", "C"], ...}
      Map.new(tasks, &{&1["name"], Map.get(&1, "requires", [])}),
      # Initially, all the tasks are pending and none processing or processed
      Enum.map(tasks, & &1["name"]),
      [],
      []
    )
    |> build_output(tasks)
  end

  # Base case - no more pending tasks, this path is finished
  defp process(_data, [] = _pending, _processing, processed), do: {:ok, processed}

  defp process(data, [task | pending], processing, processed) do
    cond do
      # If a task is "processing" it has been visited before and its path not finished.
      # If in the same path we are visiting it again, it's a cycle.
      # e.g. "A" -> "B" -> "A"
      task in processing ->
        cycle = Enum.drop_while(processing, &(&1 != task)) ++ [task]
        {:error, {:cyclic_dependencies, cycle}}

      # If the task was already processed, we just took it out of the pending, so we continue
      task in processed ->
        process(data, pending, processing, processed)

      true ->
        unprocessed_children =
          data
          |> Map.fetch!(task)
          |> Enum.reject(&Enum.member?(processed, &1))

        # We start again only with the children and consider the curren task "processing"
        with {:ok, processed} <-
               process(data, unprocessed_children, processing ++ [task], processed) do
          # Once dependencies are finished; put this task as "processed" and continue
          process(data, pending, processing, processed ++ [task])
        end
    end
  end

  defp build_output({:ok, ordered_tasks}, tasks_data) do
    by_name = Map.new(tasks_data, &{&1["name"], &1})
    {:ok, Enum.map(ordered_tasks, &Map.fetch!(by_name, &1))}
  end

  defp build_output(other, _tasks_data), do: other
end
