defmodule QWIT.Oban.FlowTest do
  use QWIT.Oban.TestCase
  alias QWIT.Oban.Flow

  doctest Flow

  test "Oban.Flow compiles" do
    defmodule TestObanFlowCompiles do
      use Flow

      @impl Flow
      def start_flow(_args, _job) do
        # no-op
      end
    end

    assert Code.ensure_loaded?(TestObanFlowCompiles)
  end

  describe "Oban.Flow functions" do
    defmodule TestObanFlowFunctions do
      use Flow

      @impl Flow
      def start_flow(args, _job) do
        enqueue_me(args)

        :ok
      end
    end

    test "enqueue_me/1 queues the Flow" do
      TestObanFlowFunctions.enqueue_me(%{})
      assert_enqueued worker: TestObanFlowFunctions, args: %{}
    end

    test "perform/1 calls start_flow/2" do
      assert :ok == %Oban.Job{args: %{arg1: :test}} |> TestObanFlowFunctions.perform()
      assert_enqueued worker: TestObanFlowFunctions, args: %{"arg1" => "test"}
    end
  end
end
