import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mine_sweeper, MineSweeperWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ZErmj0tg1ie/FSaMR/p8Yx7hOq1c2nCfvir/QO8l1KzkTpD/554FRBhLpkvjbswM",
  server: false

# In test we don't send emails.
config :mine_sweeper, MineSweeper.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
