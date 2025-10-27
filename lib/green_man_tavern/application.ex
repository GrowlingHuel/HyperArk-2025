defmodule GreenManTavern.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GreenManTavernWeb.Telemetry,
      GreenManTavern.Repo,
      {DNSCluster, query: Application.get_env(:green_man_tavern, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GreenManTavern.PubSub},
      # Start a worker by calling: GreenManTavern.Worker.start_link(arg)
      # {GreenManTavern.Worker, arg},
      # Start to serve requests, typically the last entry
      GreenManTavernWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GreenManTavern.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GreenManTavernWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
