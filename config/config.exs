import Config

config :odyssey, ecto_repos: [Odyssey.Repo]

config :odyssey, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: Odyssey.Repo

import_config "#{config_env()}.exs"
