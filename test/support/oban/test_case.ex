defmodule QWIT.Oban.TestCase do
  defmodule Repo do
    use Ecto.Repo,
      otp_app: :qwit,
      adapter: Ecto.Adapters.Postgres
  end

  use ExUnit.CaseTemplate

  using do
    quote do
      use Oban.Testing, repo: QWIT.Oban.TestCase.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias QWIT.Oban.TestCase.Repo

      setup_all do
        Repo.start_link()
        Oban.start_link(Application.get_env(:qwit, Oban))
        :ok
      end
    end
  end
end
