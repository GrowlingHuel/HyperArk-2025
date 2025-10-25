import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :green_man_tavern, GreenManTavern.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "green_man_tavern_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :green_man_tavern, GreenManTavernWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "NDjUZ6wQGLBPANgXYipKUfaUc47VliBx42lcdg/15UA+1qNrduvlWX9767sB30QS",
  server: false

# In test we don't send emails
config :green_man_tavern, GreenManTavern.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# MindsDB Configuration for Testing
# This configuration provides connection settings for MindsDB integration
# in the test environment. Test configuration uses minimal resources
# and may use mock services or test-specific MindsDB instances.
config :green_man_tavern, GreenManTavern.MindsDB,
  # Host address where MindsDB server is running during tests
  # Default: localhost (assumes MindsDB running locally for testing)
  host: "localhost",

  # HTTP API port for MindsDB REST endpoints during testing
  # This is used for querying agents and models via HTTP requests
  # Default: 48334 (MindsDB's Docker container HTTP API port)
  http_port: 48334,

  # MySQL-compatible port for direct database connections during testing
  # This port allows SQL queries to be executed directly against MindsDB
  # Default: 48335 (MindsDB's Docker container MySQL-compatible port)
  mysql_port: 48335,

  # Database name within MindsDB instance for testing
  # MindsDB uses this database to store models, agents, and data sources
  # Default: mindsdb
  database: "mindsdb",

  # Username for MindsDB authentication during testing
  # Default MindsDB installation uses 'mindsdb' as username
  username: "mindsdb",

  # Password for MindsDB authentication during testing
  # Default MindsDB installation has empty password
  password: "",

  # Connection pool size for managing concurrent database connections during testing
  # Test environment uses smaller pool to minimize resource usage
  # and ensure tests run efficiently
  pool_size: 2
