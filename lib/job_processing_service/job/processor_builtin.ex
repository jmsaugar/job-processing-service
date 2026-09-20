defmodule JobProcessingService.Job.ProcessorBuiltin do
  @moduledoc """
  Orders validated tasks using Erlang's digraph utilities.
  https://www.erlang.org/doc/apps/stdlib/digraph.html
  """

  alias JobProcessingService.Job.Processor

  @spec process_tasks([Processor.task()]) ::
          {:ok, [Processor.task()]} | {:error, {:cyclic_dependencies, [[String.t()]]}}
  def process_tasks([]), do: {:ok, []}

  def process_tasks(tasks) do
    graph = :digraph.new()

    try do
      Enum.each(tasks, &:digraph.add_vertex(graph, &1["name"]))

      Enum.each(tasks, fn task ->
        Enum.each(task["requires"] || [], &:digraph.add_edge(graph, &1, task["name"]))
      end)

      case :digraph_utils.cyclic_strong_components(graph) do
        [] ->
          names = :digraph_utils.topsort(graph)
          by_name = Map.new(tasks, &{&1["name"], &1})
          {:ok, Enum.map(names, &Map.fetch!(by_name, &1))}

        cycles ->
          {:error, {:cyclic_dependencies, cycles |> Enum.map(&Enum.reverse/1)}}
      end
    after
      :digraph.delete(graph)
    end
  end
end
