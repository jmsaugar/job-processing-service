defmodule JobProcessingService.Job.Output do
  @moduledoc """
  Builds successful and unsuccessful job responses.
  """

  alias JobProcessingService.Job.Processor

  @type t :: %{tasks: [Processor.task()]}
  @type output :: t() | String.t()
  @type format :: :json | :bash
  @type reason :: {:cyclic_dependencies, [[String.t()]]}
  @type result :: {:ok, output()} | {:error, %{error: String.t()}}

  @spec new({:ok, [Processor.task()]} | {:error, reason()}, format()) :: result()
  def new({:ok, tasks}, :json) do
    {:ok, %{tasks: Enum.map(tasks, &Map.delete(&1, "requires"))}}
  end

  def new({:ok, tasks}, :bash) do
    {:ok, Enum.join(["#!/usr/bin/env bash" | Enum.map(tasks, & &1["command"])], "\n")}
  end

  def new({:error, {:cyclic_dependencies, cycles}}, _format) do
    stringified_cycles = "[#{Enum.map_join(cycles, "] -- [", &Enum.join(&1, " -> "))}]"
    {:error, %{error: "There are tasks cycles: #{stringified_cycles}"}}
  end
end
