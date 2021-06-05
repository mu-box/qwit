defmodule QWIT do
  @moduledoc """
  Microbox QWIT is a library for building workflows out of queued worker jobs, all
  of which can be run in transactions. When errors happen, the entire workflow
  gets rewound, exactly like a failed database transaction.

  Built originally with support only for Oban, the intent is to support other
  queued worker libraries in the future, so you can drop QWIT in with whatever
  queue engine your project needs and get all the same benefits.

  Don't need a full queue engine? Check out
  [recipe](https://github.com/cloud8421/recipe) instead!
  """

  @type result ::
          :ok
          | {:ok, ignored :: term()}
          | {:error, reason :: term()}
end
