defmodule JobProcessingService.Job.Processor do
  @moduledoc """
  Processes the job payload.
  """

  def process(_body, :json) do
    # TODO
    {:ok, %{"tasks" => []}}
  end

  def process(_body, :bash) do
    # TODO
    {:ok, "script"}
  end
end
