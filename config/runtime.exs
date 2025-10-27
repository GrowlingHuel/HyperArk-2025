import Config

# Load .env file in development for local environment variables
if config_env() == :dev do
  env_file = Path.join(__DIR__, "..", ".env")
  
  if File.exists?(env_file) do
    env_file
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(fn line ->
      line = String.trim(line)
      line != "" && !String.starts_with?(line, "#")
    end)
    |> Enum.each(fn line ->
      case String.split(line, "=", parts: 2) do
        [key, value] ->
          key = String.trim(key)
          value = String.trim(value)
          # Remove quotes if present
          value = String.trim(value, "'") |> String.trim("\"")
          System.put_env(key, value)
        
        _ ->
          :skip
      end
    end)
    
    IO.puts("Loaded environment variables from .env")
  end
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/green_man_tavern start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :green_man_tavern, GreenManTavernWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  # MindsDB Runtime Configuration for Production
  # This configuration loads MindsDB connection settings from environment variables
  # for production deployment. All values can be overridden via environment variables
  # to support different deployment environments (staging, production, etc.)
  config :green_man_tavern, GreenManTavern.MindsDB,
    # Host address where MindsDB server is running
    # Can be overridden with MINDSDB_HOST environment variable
    # Default: localhost
    host: System.get_env("MINDSDB_HOST") || "localhost",

    # HTTP API port for MindsDB REST endpoints
    # Used for querying agents and models via HTTP requests
    # Can be overridden with MINDSDB_HTTP_PORT environment variable
    # Default: 48334
    http_port: String.to_integer(System.get_env("MINDSDB_HTTP_PORT") || "48334"),

    # MySQL-compatible port for direct database connections
    # Allows SQL queries to be executed directly against MindsDB
    # Can be overridden with MINDSDB_MYSQL_PORT environment variable
    # Default: 48335
    mysql_port: String.to_integer(System.get_env("MINDSDB_MYSQL_PORT") || "48335"),

    # Database name within MindsDB instance
    # Can be overridden with MINDSDB_DATABASE environment variable
    # Default: mindsdb
    database: System.get_env("MINDSDB_DATABASE") || "mindsdb",

    # Username for MindsDB authentication
    # Can be overridden with MINDSDB_USERNAME environment variable
    # Default: mindsdb
    username: System.get_env("MINDSDB_USERNAME") || "mindsdb",

    # Password for MindsDB authentication
    # Can be overridden with MINDSDB_PASSWORD environment variable
    # Default: empty string
    password: System.get_env("MINDSDB_PASSWORD") || "",

    # Connection pool size for managing concurrent database connections
    # Higher values allow more concurrent queries but use more memory
    # Can be overridden with MINDSDB_POOL_SIZE environment variable
    # Production uses larger pool for better performance
    pool_size: String.to_integer(System.get_env("MINDSDB_POOL_SIZE") || "5")

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :green_man_tavern, GreenManTavern.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :green_man_tavern, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :green_man_tavern, GreenManTavernWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :green_man_tavern, GreenManTavernWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :green_man_tavern, GreenManTavernWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :green_man_tavern, GreenManTavern.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
