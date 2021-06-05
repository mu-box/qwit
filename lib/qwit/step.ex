defmodule QWIT.Step do
  @callback step_forward(args :: map()) :: QWIT.result()
  @callback step_back(args :: map()) :: QWIT.result()

  @doc false
  defmacro __using__(opts) do
    quote location: :keep do
      use unquote(Keyword.get(opts, :backend, QWIT.Oban)).Step

      alias unquote(Keyword.get(opts, :backend, QWIT.Oban)).Step, as: Backend
      alias QWIT.Storage

      @behaviour QWIT.Step

      @impl Backend
      def start_step(
            %{
              "flow_id" => %{"name" => flow_name, "node" => flow_node},
              "flow_undo" => undo
            } = args,
            job
          ) do
        flow_id = {String.to_atom(flow_name), String.to_atom(flow_node)}
        Storage.start_link()
        Storage.put(:args, args)
        Storage.put(:job, job)

        result =
          if undo do
            step_back(args)
          else
            step_forward(args)
          end

        send(flow_id, result)
      end
    end
  end
end
