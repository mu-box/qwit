defmodule QWIT.Oban.Step do
  @callback start_step(args :: map(), job :: any()) :: QWIT.result()

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      use Oban.Worker,
        queue: :qwit,
        priority: 0,
        max_attempts: 1

      @behaviour QWIT.Oban.Step

      @impl Oban.Worker
      def perform(%Oban.Job{args: args} = job) do
        start_step(args, job)
      end

      @spec enqueue_me(map) :: boolean
      def enqueue_me(args) do
        args
        |> __MODULE__.new()
        |> Oban.insert()
      end
    end
  end
end
