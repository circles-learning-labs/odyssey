import Config

config :odyssey, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [odyssey_workers: 10],
  repo: Odyssey.Repo

import_config "#{config_env()}.exs"
