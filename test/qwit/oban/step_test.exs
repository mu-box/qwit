defmodule QWIT.Oban.StepTest do
  use QWIT.Oban.TestCase
  alias QWIT.Oban.Step

  doctest Step

  test "Step compiles for Oban" do
    defmodule TestObanStep do
      use Step

      @impl Step
      def start_step(_args, _job) do
        # no-op
      end
    end

    assert Code.ensure_loaded?(TestObanStep)
  end

  describe "Oban.Step functions" do
    defmodule TestObanStepFunctions do
      use Step

      @impl Step
      def start_step(_args, _job) do
        :ok
      end
    end

    test "perform/1 calls start_step/2" do
      assert :ok == %Oban.Job{args: %{}} |> TestObanStepFunctions.perform()
    end

    test "enqueue_me/1 queues the Step" do
      TestObanStepFunctions.enqueue_me(%{})
      assert_enqueued worker: TestObanStepFunctions, args: %{}
    end
  end
end
