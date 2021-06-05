defmodule QWIT.Flow do
  @callback build_flow() :: any()

  @type reaction ::
          {:retry, integer} | :skip | {:rollback, integer} | :skipback | :wait | {:abort, any}

  @doc false
  defmacro __using__(opts) do
    quote location: :keep do
      use unquote(Keyword.get(opts, :backend, QWIT.Oban)).Flow

      alias unquote(Keyword.get(opts, :backend, QWIT.Oban)).Flow, as: Backend
      alias QWIT.Storage

      @behaviour QWIT.Flow

      @impl Backend
      def start_flow(args, job) do
        Process.register(self(), String.to_atom(inspect(self())))
        Storage.start_link()

        Storage.put(
          :args,
          Map.merge(args, %{flow_id: %{name: inspect(self()), node: Node.self()}})
        )

        Storage.put(:job, job)

        upstream =
          case args do
            %{"flow_id" => %{"name" => flow_name, "node" => flow_node}} ->
              {String.to_atom(flow_name), String.to_atom(flow_node)}

            _else ->
              nil
          end

        build_flow()

        result =
          case args do
            %{"flow_undo" => true} ->
              do_steps(true)

            _else ->
              do_steps(false)
          end

        if not is_nil(upstream) do
          send(upstream, result)
        end

        result
      end

      @spec step(atom, map) :: any
      def step(worker, args \\ %{}) do
        Storage.put(:steps, Storage.get(:steps, []) ++ [{worker, args}])
      end

      @spec do_steps(undo :: boolean, range :: list, count :: integer) :: QWIT.result()
      defp do_steps(undo, range \\ 0..-1, count \\ 0) do
        failed_at =
          case undo do
            false ->
              Storage.get(:steps, [])
              |> Enum.slice(range)
              |> Enum.find_index(fn {worker, args} ->
                args
                |> Map.merge(Storage.get(:args, %{}))
                |> Map.merge(%{flow_undo: false})
                |> worker.enqueue_me()

                handle_message()
              end)

            true ->
              Storage.get(:steps, [])
              |> Enum.slice(range)
              |> Enum.reverse()
              |> Enum.find_index(fn {worker, args} ->
                args
                |> Map.merge(Storage.get(:args, %{}))
                |> Map.merge(%{flow_undo: true})
                |> worker.enqueue_me()

                handle_message()
              end)
          end

        result =
          if is_nil(failed_at) do
            :ok
          else
            failure_type(count)
            |> failure_react(failed_at)
          end
      end

      @spec handle_message() :: boolean
      defp handle_message do
        receive do
          :ok ->
            false

          {:ok, args} ->
            Storage.put(:args, Storage.get(:args, %{}) |> Map.merge(args))
            false

          :cancel ->
            handle_message()
            Storage.put(:failed_for, {:cancel, Storage.get(:failed_for, :ok)})
            true

          {:error, reason} ->
            Storage.put(:failed_for, reason)
            true
        end
      end

      @spec failure_type(integer, boolean) :: QWIT.Flow.reason()
      defp failure_type(count, rollback \\ false) do
        out =
          case Storage.get(:failed_for) do
            {:cancel, :ok} ->
              {:rollback, count + 1}

            {:cancel, reason} ->
              Storage.put(:failed_for, reason)

              case failure_type(count, rollback) do
                reason ->
                  {:abort, "Unhandled cancel: #{inspect(reason)}"}
              end

            reason ->
              {:abort, "Unhandled failure: #{inspect(reason)}"}
          end

        Storage.delete(:failed_for)

        out
      end

      @spec failure_react(QWIT.Flow.reaction(), integer) :: QWIT.result()
      defp failure_react(reaction, failed_at) do
        case reaction do
          {:retry, count} ->
            do_steps(false, failed_at..-1, count)

          :skip ->
            do_steps(false, (failed_at + 1)..-1, 0)

          {:rollback, count} ->
            case do_steps(true, 0..failed_at, count) do
              :ok ->
                {:error, "Rolled back"}

              result ->
                result
            end

          :skipback ->
            case do_steps(true, 0..(failed_at - 1), 0) do
              :ok ->
                {:error, "Rolled back"}

              result ->
                result
            end

          :wait ->
            receive do
              {:act, value} ->
                failure_react(value, failed_at)

              _else ->
                failure_react(reaction, failed_at)
            end

          {:abort, reason} ->
            {:error, reason}
        end
      end
    end
  end
end
