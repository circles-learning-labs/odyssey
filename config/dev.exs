import Config

config :logger, :default_handler, level: :info

config :logger, :default_formatter, format: "$time [$level] \e[7m$message\e[0m | $metadata\n"

config :odyssey, Oban,
  log: :debug,
  peer: Oban.Peers.Isolated
