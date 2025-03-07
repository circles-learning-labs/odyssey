import Config

config :odyssey, Odyssey.Repo,
  database: System.get_env("ODYSSEY_DB_DATABASE", "odyssey"),
  hostname: System.get_env("ODYSSEY_DB_HOSTNAME", "localhost"),
  password: System.get_env("ODYSSEY_DB_PASSWORD", "postgres"),
  port: System.get_env("ODYSSEY_DB_PORT", "5432") |> String.to_integer(),
  username: System.get_env("ODYSSEY_DB_USERNAME", "postgres")
