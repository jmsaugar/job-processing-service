defmodule JobProcessingService.Job.Output do
  @moduledoc """
  Builds successful and unsuccessful job responses.
  """

  alias JobProcessingService.Job.Processor

  @type t :: %{tasks: [Processor.task()]}
  @type output :: t() | String.t()
  @type format :: :json | :bash
  @type reason :: {:cyclic_dependencies, [String.t()]}
  @type result :: {:ok, output()} | {:error, %{error: String.t()}}

  @spec new({:ok, [Processor.task()]} | {:error, reason()}, format()) :: result()
  def new({:ok, tasks}, :json) do
    {:ok, %{tasks: Enum.map(tasks, &Map.delete(&1, "requires"))}}
  end

  def new({:ok, tasks}, :bash) do
    {:ok, Enum.join(["#!/usr/bin/env bash" | Enum.map(tasks, & &1["command"])], "\n")}
  end

  def new({:error, {:cyclic_dependencies, cycle}}, _format) do
    stringified_cycle = Enum.join(cycle, " -> ")
    {:error, %{error: "There is a task cycle: #{stringified_cycle}"}}
  end
end
