defmodule JobProcessingService.Job.Processor do
  @moduledoc """
  Processes the job payload.
  """

  alias JobProcessingService.Job.{Output, ProcessorBuiltin, ProcessorManual}

  # Input task has "name" and "command" as strings and optionally "requires" which is a string list
  @type task :: %{String.t() => String.t() | [String.t()]}
  @type algorithm :: :builtin | :manual

  @spec process(map(), Output.format(), algorithm) :: Output.result()
  def(process(body, format, algorithm)) do
    processor =
      case algorithm do
        :manual -> ProcessorManual
        :builtin -> ProcessorBuiltin
      end

    body["tasks"]
    |> processor.process_tasks()
    |> Output.new(format)
  end
end
