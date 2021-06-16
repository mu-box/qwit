use Mix.Config

# Configure your database
config :qwit, QWIT.Oban.TestCase.Repo,
  username: System.get_env("DATA_DB_USER") || "postgres",
  password: System.get_env("DATA_DB_PASS") || "postgres",
  hostname: System.get_env("DATA_DB_HOST") || "localhost",
  database: (if System.get_env("APP_IP"), do: "gonano", else: "qwit"),
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn

config :qwit, Oban,
  crontab: false, queues: false, plugins: false
