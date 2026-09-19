defmodule JobProcessingService.Job.ProcessorTest do
  use ExUnit.Case, async: true

  alias JobProcessingService.Job.Processor

  for algorithm <- [:manual, :builtin] do
    test "processes an empty task list (#{algorithm})" do
      assert Processor.process(%{"tasks" => []}, :json, unquote(algorithm)) == {:ok, %{tasks: []}}
    end

    test "works with independent tasks with no dependencies (#{algorithm})" do
      first = %{"name" => "first", "command" => "echo first"}
      second = %{"name" => "second", "command" => "echo second"}

      result = Processor.process(%{"tasks" => [first, second]}, :json, unquote(algorithm))

      # Technically both results would be ok
      assert result == {:ok, %{tasks: [first, second]}} or
               result == {:ok, %{tasks: [second, first]}}
    end

    test "works with a reversed chained dependencies and removes dependencies from JSON output (#{algorithm})" do
      tasks = [task("last", ["middle"]), task("middle", ["first"]), task("first")]

      assert Processor.process(%{"tasks" => tasks}, :json, unquote(algorithm)) ==
               {:ok, %{tasks: [task("first"), task("middle"), task("last")]}}
    end

    test "works with exercise specification example (#{algorithm})" do
      task1 = task("task-1", "touch /tmp/file1")
      task2 = task("task-2", "cat /tmp/file1", ["task-3"])
      task3 = task("task-3", "echo 'Hello World!' > /tmp/file1", ["task-1"])
      task4 = task("task-4", "rm /tmp/file1", ["task-2", "task-3"])

      tasks = [
        task1,
        task2,
        task3,
        task4
      ]

      assert {:ok, %{tasks: ordered}} =
               Processor.process(%{"tasks" => tasks}, :json, unquote(algorithm))

      assert ordered ==
               Enum.map([task1, task3, task2, task4], fn t -> Map.delete(t, "requires") end)
    end

    test "detects a cycle between two tasks (#{algorithm})" do
      task1 = task("task-1", "echo first", ["task-2"])
      task2 = task("task-2", "echo second", ["task-1"])

      tasks = [
        task1,
        task2
      ]

      assert {:error, %{error: message}} =
               Processor.process(%{"tasks" => tasks}, :json, unquote(algorithm))

      assert message =~ "There are tasks cycles:"
    end

    test "detects a cycle across three tasks (#{algorithm})" do
      task1 = task("task-1", "echo first", ["task-2"])
      task2 = task("task-2", "echo second", ["task-3"])
      task3 = task("task-3", "echo third", ["task-1"])

      tasks = [
        task1,
        task2,
        task3
      ]

      assert {:error, %{error: message}} =
               Processor.process(%{"tasks" => tasks}, :json, unquote(algorithm))

      assert message =~ "There are tasks cycles:"
    end

    test "detects a cycle reached from another task (#{algorithm})" do
      task1 = task("task-1", "echo first", ["task-2"])
      task2 = task("task-2", "echo second", ["task-3"])
      task3 = task("task-3", "echo third", ["task-2"])

      tasks = [
        task1,
        task2,
        task3
      ]

      assert {:error, %{error: message}} =
               Processor.process(%{"tasks" => tasks}, :json, unquote(algorithm))

      assert message =~ "There are tasks cycles:"
    end
  end

  defp task(name), do: %{"name" => name, "command" => "echo #{name}"}
  defp task(name, command) when is_binary(command), do: %{"name" => name, "command" => command}
  defp task(name, requires), do: Map.put(task(name), "requires", requires)
  defp task(name, command, requires), do: Map.put(task(name, command), "requires", requires)
end
