defmodule GreenManTavern.MindsDB.Connection do
  @moduledoc """
  GenServer for managing MindsDB connections and health monitoring.

  This module provides a supervised process that continuously monitors the health
  of MindsDB connections using both HTTP and SQL clients. It tracks connection
  status, consecutive failures, and automatically logs when connections are
  lost or restored.

  ## Features

  - **Dual Health Checking**: Uses both HTTP and SQL clients for comprehensive monitoring
  - **Periodic Monitoring**: Automatically checks health every 60 seconds
  - **Failure Tracking**: Counts consecutive failures for better diagnostics
  - **Status Reporting**: Provides real-time connection status
  - **Manual Triggers**: Supports forced health checks for immediate verification

  ## Usage

      # Start the connection manager
      {:ok, pid} = GreenManTavern.MindsDB.Connection.start_link([])

      # Check if MindsDB is healthy
      healthy? = GreenManTavern.MindsDB.Connection.healthy?()

      # Get detailed status
      {:ok, :connected} = GreenManTavern.MindsDB.Connection.get_status()

      # Force immediate health check
      GreenManTavern.MindsDB.Connection.force_health_check()
  """

  use GenServer
  require Logger

  # Client API

  @doc """
  Starts the MindsDB connection manager.

  ## Options

  - `:health_check_interval` - Interval between health checks in milliseconds (default: 60_000)
  - `:max_consecutive_failures` - Maximum failures before marking as unhealthy (default: 3)

  ## Examples

      iex> GreenManTavern.MindsDB.Connection.start_link([])
      {:ok, #PID<0.123.0>}

      iex> GreenManTavern.MindsDB.Connection.start_link(health_check_interval: 30_000)
      {:ok, #PID<0.124.0>}
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if MindsDB is currently healthy.

  Returns `true` if the last health check was successful, `false` otherwise.

  ## Examples

      iex> GreenManTavern.MindsDB.Connection.healthy?()
      true

      iex> GreenManTavern.MindsDB.Connection.healthy?()
      false
  """
  @spec healthy?() :: boolean()
  def healthy? do
    GenServer.call(__MODULE__, :healthy?)
  end

  @doc """
  Gets the current connection status.

  Returns `{:ok, :connected}` if healthy, `{:error, :disconnected}` if unhealthy.

  ## Examples

      iex> GreenManTavern.MindsDB.Connection.get_status()
      {:ok, :connected}

      iex> GreenManTavern.MindsDB.Connection.get_status()
      {:error, :disconnected}
  """
  @spec get_status() :: {:ok, :connected} | {:error, :disconnected}
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @doc """
  Forces an immediate health check.

  Triggers a health check regardless of the scheduled interval.
  Useful for testing or when immediate verification is needed.

  ## Examples

      iex> GreenManTavern.MindsDB.Connection.force_health_check()
      :ok
  """
  @spec force_health_check() :: :ok
  def force_health_check do
    GenServer.cast(__MODULE__, :force_health_check)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    health_check_interval = Keyword.get(opts, :health_check_interval, 60_000)
    max_consecutive_failures = Keyword.get(opts, :max_consecutive_failures, 3)

    state = %{
      healthy: false,
      consecutive_failures: 0,
      max_consecutive_failures: max_consecutive_failures,
      health_check_interval: health_check_interval,
      last_check: nil
    }

    # Schedule initial health check
    schedule_health_check(health_check_interval)

    Logger.info("MindsDB Connection manager started",
      health_check_interval: health_check_interval,
      max_consecutive_failures: max_consecutive_failures
    )

    {:ok, state}
  end

  @impl true
  def handle_call(:healthy?, _from, state) do
    {:reply, state.healthy, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = if state.healthy, do: {:ok, :connected}, else: {:error, :disconnected}
    {:reply, status, state}
  end

  @impl true
  def handle_cast(:force_health_check, state) do
    Logger.info("Forced health check triggered")
    new_state = perform_health_check(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:health_check, state) do
    new_state = perform_health_check(state)
    schedule_health_check(state.health_check_interval)
    {:noreply, new_state}
  end

  # Private Functions

  defp perform_health_check(state) do
    Logger.debug("Performing MindsDB health check")

    case check_health() do
      :ok ->
        handle_healthy_check(state)

      {:error, reason} ->
        handle_unhealthy_check(state, reason)
    end
  end

  defp check_health do
    # Check HTTP client first (faster)
    case GreenManTavern.MindsDB.HTTPClient.get_status() do
      {:ok, _} ->
        # HTTP is working, also check SQL client
        case GreenManTavern.MindsDB.SQLClient.query("SELECT 1 as test") do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, {:sql_check_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:http_check_failed, reason}}
    end
  end

  defp handle_healthy_check(state) do
    new_state = %{state | healthy: true, consecutive_failures: 0, last_check: DateTime.utc_now()}

    # Log restoration if we were previously unhealthy
    if state.consecutive_failures > 0 do
      Logger.info("MindsDB connection restored",
        consecutive_failures: state.consecutive_failures
      )
    end

    Logger.debug("MindsDB health check passed")
    new_state
  end

  defp handle_unhealthy_check(state, reason) do
    new_failures = state.consecutive_failures + 1

    new_state = %{
      state
      | healthy: false,
        consecutive_failures: new_failures,
        last_check: DateTime.utc_now()
    }

    # Log failure details
    Logger.warning("MindsDB health check failed",
      reason: reason,
      consecutive_failures: new_failures,
      max_failures: state.max_consecutive_failures
    )

    # Log connection lost if this is the first failure
    if new_failures == 1 do
      Logger.error("MindsDB connection lost", reason: reason)
    end

    # Log critical failure if we've exceeded max failures
    if new_failures >= state.max_consecutive_failures do
      Logger.error("MindsDB connection critically unhealthy",
        consecutive_failures: new_failures,
        max_failures: state.max_consecutive_failures
      )
    end

    new_state
  end

  defp schedule_health_check(interval) do
    Process.send_after(self(), :health_check, interval)
  end
end
