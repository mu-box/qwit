# Queued Workflows In Transactions

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mu-box/qwit/Elixir%20CI)
![Hex.pm](https://img.shields.io/hexpm/l/qwit)
![Hex.pm](https://img.shields.io/hexpm/v/qwit)
![Hex.pm](https://img.shields.io/hexpm/dt/qwit)
![Discord](https://img.shields.io/discord/610589644651888651)
![GitHub Sponsors](https://img.shields.io/github/sponsors/mu-box)

Microbox QWIT is a library for building workflows out of queued worker jobs, and
running them as transactions. When errors happen, the entire workflow gets
rewound, exactly like a failed database transaction.

Built originally with support only for Oban, the intent is to support other
queued worker libraries in the future, so you can drop QWIT in with whatever
queue engine your project needs and get all the same benefits.

Don't need a full queue engine? Check out
[recipe](https://github.com/cloud8421/recipe) instead!

## Why?

Microbox Core performs tasks that need to be reversible in case of failures.
Since this portion of the project is so reusable elsewhere, it made sense to
extract it into its own package. While Core uses Oban to improve scalability, it
makes sense to support as many queue engines as possible for maximum
flexibility, so that's how we approach the architecture.

## Installation

Add QWIT to your `mix.exs` with your other `deps`:

```elixir
{:qwit, "~> 0.1.0"},
```

Then, as usual, `mix deps.get` and you'll be set! Nothing to configure, here.

## Usage

QWIT provides a common interface to all supported queue engines. That means all
you have to do is swap out your engine, update your modules, and everything else
works as before. You can even use multiple engines at once, since the
appropriate engine is passed as a `use` option.

Workflows are provided by two module types - Flows and Steps. Flows dictate
which steps are run in which order.

<!-- TODO: Come up with a more useful example here... -->

```elixir
defmodule MyApp.Work.Flows.Example do
  use QWIT.Flow

  @impl QWIT.Flow
  def build_flow do
    step MyApp.Work.Steps.Example, %{arg1: "value1"}
    step MyApp.Work.Steps.Example
  end
end
```

Steps do the actual work, with the return values of each serving as additional
arguments to the next.

```elixir
defmodule MyApp.Work.Steps.Example
  use QWIT.Step

  import Logger

  @impl QWIT.Step
  def step_forward(%{arg1: arg1}) do
    Logger.info("Got first arg: #{arg1}")

    {:ok, %{arg2: "value2"}} # pass arg2 to following steps in flow
  end
  def step_forward(%{arg2: arg2}) do
    Logger.info("Got second arg: #{arg2}")
  end

  @impl QWIT.Step
  def step_back(%{} = _args) do
    Logger.info("Something went horribly wrong...")
  end
end
```

For especially complex workflows, you can call sub-Flows as though they were
Steps - QWIT handles the differences transparently behind the scenes.

```elixir
defmodule MyApp.Work.Flows.Example2 do
  use QWIT.Flow

  @impl QWIT.Flow
  def build_flow do
    step MyApp.Work.Flows.Example, %{arg3: "value3"} # arg3 is available to all steps in sub-Flow
    step MyApp.Work.Steps.Example
  end
end
```

### Oban

Oban is the default backend, so you don't have to do anything special to use it.
However, if you prefer to be explicit, you can pass `backend: QWIT.Oban` to your
`use` statements:

```elixir
  use QWIT.Flow, backend: QWIT.Oban
```

```elixir
  use QWIT.Step, backend: QWIT.Oban
```

### Custom Engines

Don't see your engine listed here? That's fine - you can write your own! PRs are
also happily accepted. Have a look at the `flow.ex` and `step.ex` in
`lib/qwit/oban` for a good example of how this looks, and how simple it is to
build your own. Don't forget to tell QWIT where to look for your backend!

```elixir
  use QWIT.Flow, backend: MyBackend
```

```elixir
  use QWIT.Step, backend: MyBackend
```

## Feedback

To submit feedback, please use the project's
[GitHub Issues](https://github.com/mu-box/qwit/issues). Unless the feedback is a
security issue; in that case, email [Dan](mailto:dan.hunsaker+qwit@gmail.com)
directly.
