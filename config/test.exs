import Config

config :logger, :default_handler, level: :warning

# The default oban peer has a 30 second timeout which can break subsequent test runs.
# Use the simple, single-noded, isolated peer for tests.
config :odyssey, Oban, peer: Oban.Peers.Isolated
