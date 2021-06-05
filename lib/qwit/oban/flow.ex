defmodule QWIT.Oban.Flow do
  @callback start_flow(args :: map(), job :: any()) :: QWIT.result()

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      use Oban.Worker,
        queue: :qwit,
        priority: 1,
        max_attempts: 1

      alias QWIT.Storage

      @behaviour QWIT.Oban.Flow

      @impl Oban.Worker
      def perform(%Oban.Job{args: args} = job) do
        start_flow(args, job)
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
