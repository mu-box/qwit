defmodule QWIT.StepTest do
  use ExUnit.Case
  alias QWIT.Step

  doctest Step

  test "Step compiles for Oban" do
    defmodule ObanTestStep do
      use Step, backend: QWIT.Oban

      @impl Step
      def step_forward(_args) do
        # no-op
      end

      @impl Step
      def step_back(_args) do
        # no-op
      end
    end

    assert Code.ensure_loaded?(ObanTestStep)
  end

  test "Step doesn't compile for NotExists" do
    assert_raise CompileError, fn ->
      defmodule NotExistsTestStep do
        use Step, backend: NotExists

        @impl Step
        def step_forward(_args) do
          # no-op
        end

        @impl Step
        def step_back(_args) do
          # no-op
        end
      end
    end

    assert not Code.ensure_loaded?(NotExistsTestStep)
  end

  describe "Step functions" do
    defmodule TestStepFunctions do
      use Step, backend: QWIT.Task

      @impl Step
      def step_forward(_args) do
        :forward
      end

      @impl Step
      def step_back(_args) do
        :back
      end
    end

    setup do
      Process.register(self(), String.to_atom(inspect(self())))
      %{flow_id: %{"name" => inspect(self()), "node" => Atom.to_string(Node.self())}}
    end

    test "start_step/2 calls step_forward/1 when not in undo mode", %{flow_id: flow_id} do
      assert :forward =
               %{"flow_id" => flow_id, "flow_undo" => false}
               |> TestStepFunctions.start_step(%{})
    end

    test "start_step/2 calls step_back/1 when in undo mode", %{flow_id: flow_id} do
      assert :back =
               %{"flow_id" => flow_id, "flow_undo" => true}
               |> TestStepFunctions.start_step(%{})
    end

    test "start_step/2 passes result to parent process", %{flow_id: flow_id} do
      %{"flow_id" => flow_id, "flow_undo" => false}
      |> TestStepFunctions.start_step(%{})
      assert_received :forward

      %{"flow_id" => flow_id, "flow_undo" => true}
      |> TestStepFunctions.start_step(%{})
      assert_received :back
    end

    test "start_step/2 stores args", %{flow_id: flow_id} do
      args = %{"flow_id" => flow_id, "flow_undo" => false}

      TestStepFunctions.start_step(args, %{})

      assert QWIT.Storage.get(:args) == args
    end

    test "start_step/2 stores job", %{flow_id: flow_id} do
      job = %{key: :test}

      %{"flow_id" => flow_id, "flow_undo" => false}
      |> TestStepFunctions.start_step(job)

      assert QWIT.Storage.get(:job) == job
    end

    test "start_step/2 stores values in own process, not globally", %{flow_id: flow_id} do
      QWIT.Storage.start_link()

      Task.async(fn ->
        %{"flow_id" => flow_id, "flow_undo" => false}
        |> TestStepFunctions.start_step(%{})
      end)
      |> Task.await()

      assert nil == QWIT.Storage.get(:args)
      assert nil == QWIT.Storage.get(:job)
    end
  end
end
