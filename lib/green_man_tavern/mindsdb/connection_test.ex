defmodule GreenManTavern.MindsDB.ConnectionTest do
  @moduledoc """
  Minimal utilities for verifying MindsDB HTTP connectivity.
  """

  require Logger
  alias GreenManTavern.MindsDB.Client

  @doc """
  Tests the HTTP connection to MindsDB.
  """
  def test_connection do
    Logger.info("Testing MindsDB connection...")
    Client.test_connection()
  end

  @doc """
  Lists available MindsDB agents/models.
  """
  def list_agents do
    Logger.info("Fetching MindsDB agents...")
    Client.list_agents()
  end

  @doc """
  Tests a simple agent query using the HTTP client.
  """
  def test_agent_query(agent_name \\ "student_agent", test_message \\ "Hello") do
    Logger.info("Testing agent query: #{agent_name}")
    test_context = %{user_location: "Zone 8b", user_space: "apartment", user_skill: "beginner"}
    Client.query_agent(agent_name, test_message, test_context)
  end
end
