defmodule QWIT.FlowTest do
  use ExUnit.Case
  alias QWIT.Flow

  doctest Flow

  test "Flow compiles for Oban" do
    defmodule ObanTestFlow do
      use Flow, backend: QWIT.Oban

      @impl Flow
      def build_flow do
        # no-op
      end
    end

    assert Code.ensure_loaded?(ObanTestFlow)
  end

  test "Flow doesn't compile for NotExists" do
    assert_raise CompileError, fn ->
      defmodule NotExistsTestFlow do
        use Flow, backend: NotExists

        @impl Flow
        def build_flow do
          # no-op
        end
      end
    end

    assert not Code.ensure_loaded?(NotExistsTestFlow)
  end

  describe "Flow functions" do
    defmodule TestFlowFunctions do
      use Flow, backend: QWIT.Task

      @impl Flow
      def build_flow do
        step QWIT.FlowTest.TestFlowFunctionsStep, %{step: 1}
        step QWIT.FlowTest.TestFlowFunctionsSubFlow, %{flow: 2}
      end
    end

    defmodule TestFlowFunctionsSubFlow do
      use Flow, backend: QWIT.Task

      @impl Flow
      def build_flow do
        step QWIT.FlowTest.TestFlowFunctionsStep, %{step: 2}
      end
    end

    defmodule TestFlowFunctionsStep do
      use QWIT.Step, backend: QWIT.Task

      @impl QWIT.Step
      def step_forward(_args) do
        :ok
      end

      @impl QWIT.Step
      def step_back(_args) do
        :ok
      end
    end

    test "step/1,2 stores steps" do
      QWIT.Storage.start_link()

      assert QWIT.Storage.get(:steps) == nil

      TestFlowFunctions.step TestFlowFunctionsStep

      assert QWIT.Storage.get(:steps) == [
        {TestFlowFunctionsStep, %{}}
      ]

      TestFlowFunctions.step TestFlowFunctionsSubFlow, %{arg1: :test}

      assert QWIT.Storage.get(:steps) == [
        {TestFlowFunctionsStep, %{}},
        {TestFlowFunctionsSubFlow, %{arg1: :test}}
      ]
    end

    test "start_flow/2 stores args" do
      args = %{arg1: :test}

      TestFlowFunctions.start_flow(args, %{})

      assert QWIT.Storage.get(:args) |> Map.delete(:flow_id) == args
    end

    test "start_flow/2 stores job" do
      job = %{key: :test}

      TestFlowFunctions.start_flow(%{}, job)

      assert QWIT.Storage.get(:job) == job
    end

    test "start_flow/2 stores values in own process, not globally" do
      QWIT.Storage.start_link()

      Task.async(fn () ->
        TestFlowFunctions.start_flow(%{}, %{})
      end)
      |> Task.await()

      assert nil == QWIT.Storage.get(:args)
      assert nil == QWIT.Storage.get(:job)
    end

    test "start_flow/2 calls build_flow/0" do
      Task.async(fn () ->
        TestFlowFunctions.start_flow(%{}, %{})

        assert QWIT.Storage.get(:steps) == [
          {QWIT.FlowTest.TestFlowFunctionsStep, %{step: 1}},
          {QWIT.FlowTest.TestFlowFunctionsSubFlow, %{flow: 2}}
        ]
      end)
      |> Task.await()

      Task.async(fn () ->
        TestFlowFunctionsSubFlow.start_flow(%{}, %{})

        assert QWIT.Storage.get(:steps) == [
          {QWIT.FlowTest.TestFlowFunctionsStep, %{step: 2}}
        ]
      end)
      |> Task.await()
    end

    # TODO: More tests

    test "start_flow/2 returns result" do
      assert :ok == TestFlowFunctions.start_flow(%{}, %{})
    end
  end
end
