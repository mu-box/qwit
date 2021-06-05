defmodule QWIT.Task.Step do
  @callback start_step(args :: map(), job :: any()) :: QWIT.result()

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour QWIT.Task.Step

      @spec perform(map) :: QWIT.result()
      def perform(%{args: args} = job) do
        start_step(args, job)
      end

      @spec enqueue_me(map) :: boolean
      def enqueue_me(args) do
        Task.async(fn ->
          perform(%{args: args |> Jason.encode!() |> Jason.decode!()})
        end)
        |> Task.await()

        true
      end
    end
  end
end
