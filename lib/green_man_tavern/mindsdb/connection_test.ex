defmodule GreenManTavern.MindsDB.ConnectionTest do
  @moduledoc """
  Test module for verifying MindsDB connection and functionality.

  This module provides utility functions for debugging MindsDB connectivity
  and testing agent queries. It's designed for development and debugging use.
  """

  require Logger
  alias GreenManTavern.MindsDB.Client
  alias GreenManTavern.MindsDB.QueryBuilder

  @doc """
  Tests the connection to MindsDB.

  ## Returns
  - `{:ok, "Connection successful"}` - If connection works
  - `{:error, reason}` - If connection fails with helpful error message

  ## Example
      iex> ConnectionTest.test_connection()
      {:ok, "Connection successful"}
  """
  def test_connection do
    Logger.info("Testing MindsDB connection...")

    case Client.test_connection() do
      {:ok, message} ->
        Logger.info("✅ MindsDB connection successful")
        {:ok, message}

      {:error, reason} ->
        Logger.error("❌ MindsDB connection failed: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Lists all available MindsDB agents/models.

  ## Returns
  - `{:ok, [agent_names]}` - List of available agent names
  - `{:error, reason}` - Error if query fails

  ## Example
      iex> ConnectionTest.list_agents()
      {:ok, ["student_agent", "farmer_agent", "grandmother_agent"]}
  """
  def list_agents do
    Logger.info("Fetching MindsDB agents...")

    case Client.list_agents() do
      {:ok, agents} ->
        Logger.info("✅ Found #{length(agents)} agents: #{Enum.join(agents, ", ")}")
        {:ok, agents}

      {:error, reason} ->
        Logger.error("❌ Failed to list agents: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Gets detailed information about a specific agent.

  ## Parameters
  - `agent_name` - The name of the agent to inspect

  ## Returns
  - `{:ok, agent_info}` - Agent information
  - `{:error, reason}` - Error if agent not found

  ## Example
      iex> ConnectionTest.get_agent_info("student_agent")
      {:ok, [["name", "type", "status", "accuracy"]]}
  """
  def get_agent_info(agent_name) do
    Logger.info("Getting info for agent: #{agent_name}")

    case Client.get_agent_info(agent_name) do
      {:ok, info} ->
        Logger.info("✅ Agent info retrieved for #{agent_name}")
        {:ok, info}

      {:error, reason} ->
        Logger.error("❌ Failed to get agent info: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Tests a simple query to a MindsDB agent.

  ## Parameters
  - `agent_name` - The agent to test (default: "student_agent")
  - `test_message` - The test message to send (default: "Hello")

  ## Returns
  - `{:ok, response}` - Agent response
  - `{:error, reason}` - Error if query fails

  ## Example
      iex> ConnectionTest.test_agent_query("student_agent", "What is permaculture?")
      {:ok, "Permaculture is a design philosophy..."}
  """
  def test_agent_query(agent_name \\ "student_agent", test_message \\ "Hello") do
    Logger.info("Testing agent query: #{agent_name} with message: #{test_message}")

    # Build test context
    test_context = %{
      user_location: "Zone 8b",
      user_space: "apartment",
      user_skill: "beginner",
      climate_zone: "Zone 8b",
      user_systems: ["herb_garden"],
      user_projects: []
    }

    case Client.query_agent(agent_name, test_message, test_context) do
      {:ok, response} ->
        Logger.info("✅ Agent query successful")
        Logger.info("Response: #{String.slice(response, 0, 200)}...")
        {:ok, response}

      {:error, reason} ->
        Logger.error("❌ Agent query failed: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Runs a comprehensive test suite for MindsDB integration.

  This function tests:
  1. Connection to MindsDB
  2. Listing available agents
  3. Testing a simple agent query
  4. Validating query builder functions

  ## Returns
  - `{:ok, test_results}` - Summary of all tests
  - `{:error, reason}` - Error if any critical test fails
  """
  def run_test_suite do
    Logger.info("🧪 Starting MindsDB test suite...")

    results = %{
      connection_test: test_connection(),
      agents_test: list_agents(),
      query_test: test_agent_query(),
      query_builder_test: test_query_builder()
    }

    # Check if all critical tests passed
    critical_tests = [:connection_test, :query_test]
    failed_tests = Enum.filter(critical_tests, fn test ->
      case Map.get(results, test) do
        {:error, _} -> true
        _ -> false
      end
    end)

    if Enum.empty?(failed_tests) do
      Logger.info("✅ All critical tests passed!")
      {:ok, results}
    else
      Logger.error("❌ Critical tests failed: #{Enum.join(failed_tests, ", ")}")
      {:error, "Critical tests failed: #{Enum.join(failed_tests, ", ")}"}
    end
  end

  @doc """
  Tests the query builder functionality.
  """
  def test_query_builder do
    Logger.info("Testing query builder...")

    test_cases = [
      {"student_agent", "What should I plant?", %{climate_zone: "8b"}},
      {"farmer_agent", "How do I compost?", %{user_space: "backyard"}},
      {"invalid_agent", "Test message", %{}}
    ]

    results = Enum.map(test_cases, fn {agent, message, context} ->
      case QueryBuilder.build_agent_query(agent, message, context) do
        {:ok, query} ->
          Logger.info("✅ Query built successfully for #{agent}")
          {:ok, query}

        {:error, reason} ->
          Logger.warning("⚠️ Query build failed for #{agent}: #{reason}")
          {:error, reason}
      end
    end)

    {:ok, results}
  end

  @doc """
  Provides helpful debugging information about MindsDB configuration.
  """
  def debug_config do
    mindsdb_config = Application.get_env(:green_man_tavern, :mindsdb, [])

    Logger.info("🔧 MindsDB Configuration:")
    Logger.info("  Host: #{Keyword.get(mindsdb_config, :host, "not set")}")
    Logger.info("  Port: #{Keyword.get(mindsdb_config, :port, "not set")}")
    Logger.info("  User: #{Keyword.get(mindsdb_config, :user, "not set")}")
    Logger.info("  Database: #{Keyword.get(mindsdb_config, :database, "not set")}")

    mindsdb_config
  end

  @doc """
  Checks if MindsDB is running and accessible.

  This is a quick health check that can be used in monitoring.
  """
  def health_check do
    case test_connection() do
      {:ok, _} -> :healthy
      {:error, _} -> :unhealthy
    end
  end
end

