import Config

config :odyssey, ecto_repos: [Odyssey.Repo]

config :odyssey, Oban,
  repo: Odyssey.Repo,
  queues: [workers: 10]
