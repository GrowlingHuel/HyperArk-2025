# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :green_man_tavern,
  ecto_repos: [GreenManTavern.Repo],
  generators: [timestamp_type: :utc_datetime_usec],
  environment: config_env()

# Configures the endpoint
config :green_man_tavern, GreenManTavernWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: GreenManTavernWeb.ErrorHTML, json: GreenManTavernWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GreenManTavern.PubSub,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT", "64kWefz5")],
  session: [
    store: :cookie,
    key: "_green_man_tavern_key",
    signing_salt: System.get_env("SESSION_SIGNING_SALT", "1DDWx4YS"),
    max_age: 60 * 60 * 24 * 60,  # 60 days
    http_only: true,              # Prevents JavaScript access (XSS protection)
    secure: Application.compile_env(:green_man_tavern, :environment) != :dev,  # HTTPS-only in production
    same_site: "Lax"              # CSRF protection
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :green_man_tavern, GreenManTavern.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  green_man_tavern: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  green_man_tavern: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
