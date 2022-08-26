import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :todoish, TodoishWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6XO/DAtv2i00BPW92c4S2lYjV7nnv/p+2GQ28ak/PcSPuYwJ0ORJbLfzhiNHgn4O",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
