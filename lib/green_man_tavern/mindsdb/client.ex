defmodule GreenManTavern.MindsDB.Client do
  @moduledoc """
  Client for connecting to and querying MindsDB agents.

  MindsDB uses PostgreSQL wire protocol, so we can connect using Postgrex.
  This module provides a connection pool and query interface for MindsDB agents.
  """

  use GenServer
  require Logger

  @timeout 30_000  # 30 seconds timeout for queries

  # Client API

  @doc """
  Starts the MindsDB client GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Tests the connection to MindsDB.
  Returns {:ok, "Connection successful"} or {:error, reason}
  """
  def test_connection do
    GenServer.call(__MODULE__, :test_connection, @timeout)
  end

  @doc """
  Queries a MindsDB agent with a message and context.

  ## Parameters
  - `agent_name` - The name of the MindsDB agent/model
  - `message` - The user's message to send to the agent
  - `context` - A map of context data to inject into the query

  ## Returns
  - `{:ok, response}` - Success with agent response
  - `{:error, reason}` - Error with reason
  """
  def query_agent(agent_name, message, context \\ %{}) do
    GenServer.call(__MODULE__, {:query_agent, agent_name, message, context}, @timeout)
  end

  @doc """
  Lists available MindsDB models/agents.
  """
  def list_agents do
    GenServer.call(__MODULE__, :list_agents, @timeout)
  end

  @doc """
  Gets information about a specific agent.
  """
  def get_agent_info(agent_name) do
    GenServer.call(__MODULE__, {:get_agent_info, agent_name}, @timeout)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    # Start connection with explicit non-SSL options for MindsDB's PG wire protocol
    conn_config = connection_opts()

    case Postgrex.start_link(conn_config) do
      {:ok, conn} ->
        Logger.info("MindsDB client started successfully")
        {:ok, %{conn: conn, config: conn_config}}

      {:error, reason} ->
        Logger.error("Failed to start MindsDB client: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def handle_call(:test_connection, _from, state) do
    case Postgrex.query(state.conn, "SELECT 1 as test", []) do
      {:ok, _result} ->
        {:reply, {:ok, "Connection successful"}, state}

      {:error, reason} ->
        error_msg = case reason do
          %Postgrex.Error{postgres: %{code: :connection_refused}} ->
            "MindsDB is not running. Start it with: docker start mindsdb"
          %Postgrex.Error{postgres: %{code: :invalid_authorization_specification}} ->
            "Check MindsDB username/password in config/dev.exs"
          %Postgrex.Error{postgres: %{code: :connection_timeout}} ->
            "MindsDB is slow to respond, try again in a moment"
          _ ->
            "MindsDB connection error: #{inspect(reason)}"
        end
        {:reply, {:error, error_msg}, state}
    end
  end

  @impl true
  def handle_call({:query_agent, agent_name, message, context}, _from, state) do
    Logger.info("🎯 CALLING MINDSDB: #{agent_name} with: #{message}")

    # Build the SQL query with context injection
    query = build_agent_query(agent_name, message, context)

    case Postgrex.query(state.conn, query, []) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        response = case rows do
          [[response_text]] when is_binary(response_text) ->
            response_text
          [[response_text]] when is_map(response_text) ->
            Jason.encode!(response_text)
          [] ->
            "No response from agent"
          _ ->
            "Unexpected response format"
        end
        {:reply, {:ok, response}, state}

      {:error, reason} ->
        Logger.error("MindsDB query error: #{inspect(reason)}")
        {:reply, {:error, "Query failed: #{inspect(reason)}"}, state}
    end
  end

  @impl true
  def handle_call(:list_agents, _from, state) do
    query = "SHOW MODELS WHERE type = 'model'"

    case Postgrex.query(state.conn, query, []) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        agents = Enum.map(rows, fn [name | _] -> name end)
        {:reply, {:ok, agents}, state}

      {:error, reason} ->
        {:reply, {:error, "Failed to list agents: #{inspect(reason)}"}, state}
    end
  end

  @impl true
  def handle_call({:get_agent_info, agent_name}, _from, state) do
    query = "DESCRIBE #{agent_name}"

    case Postgrex.query(state.conn, query, []) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        {:reply, {:ok, rows}, state}

      {:error, reason} ->
        {:reply, {:error, "Failed to get agent info: #{inspect(reason)}"}, state}
    end
  end

  # Private Functions

  defp build_agent_query(agent_name, message, context) do
    # Sanitize inputs
    safe_agent_name = sanitize_agent_name(agent_name)
    safe_message = sanitize_input(message)

    # Build context string
    context_str = case context do
      %{} = ctx when map_size(ctx) > 0 ->
        Jason.encode!(ctx)
      _ ->
        "{}"
    end

    # Construct the SQL query
    """
    SELECT answer
    FROM mindsdb.#{safe_agent_name}
    WHERE question = '#{safe_message}'
    AND user_context = '#{context_str}'
    """
  end

  defp connection_opts do
    [
      hostname: Application.get_env(:green_man_tavern, :mindsdb_host, "localhost"),
      port: Application.get_env(:green_man_tavern, :mindsdb_port, 47340),
      username: Application.get_env(:green_man_tavern, :mindsdb_user, "mindsdb"),
      password: Application.get_env(:green_man_tavern, :mindsdb_password, "mindsdb"),
      database: Application.get_env(:green_man_tavern, :mindsdb_database, "mindsdb"),
      ssl: false,
      pool_size: 5,
      timeout: 30_000,
      connect_timeout: 30_000,
      handshake_timeout: 30_000,
      types: Postgrex.DefaultTypes
    ]
  end

  defp sanitize_agent_name(name) do
    # Whitelist of allowed agent names
    allowed_agents = [
      "student_agent",
      "grandmother_agent",
      "farmer_agent",
      "robot_agent",
      "alchemist_agent",
      "survivalist_agent",
      "hobo_agent"
    ]

    if name in allowed_agents do
      name
    else
      Logger.warning("Invalid agent name: #{name}")
      "student_agent"  # Default fallback
    end
  end

  defp sanitize_input(text) do
    # Basic SQL injection prevention
    text
    |> String.replace("'", "''")  # Escape single quotes
    |> String.replace(";", "")    # Remove semicolons
    |> String.replace("--", "")   # Remove SQL comments
    |> String.slice(0, 1000)      # Limit length
  end
end
