defmodule GreenManTavern.MindsDB.Client do
  @moduledoc """
  MindsDB Client for querying AI agents.

  This module handles communication with MindsDB agents,
  providing a clean interface for sending messages and receiving responses.
  """

  @doc """
  Queries a MindsDB agent with a message and context.

  ## Parameters
  - `agent_name` - The name of the MindsDB agent to query
  - `message` - The user's message to send to the agent
  - `context` - Additional context information for the agent

  ## Returns
  - `{:ok, response}` - Success with agent response
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> query_agent("the_grandmother", "Hello", "User context...")
      {:ok, "Hello! I'm the_grandmother. You said: Hello. Context: User context..."}

  """
  def query_agent(agent_name, message, context) do
    IO.puts("🎯 CALLING MINDSDB: #{agent_name} with: #{message}")
    # For now, return a mock response
    # TODO: Implement actual MindsDB API integration
    {:ok, "Hello! I'm #{agent_name}. You said: #{message}. Context: #{context}"}
  end

  @doc """
  Queries a MindsDB agent with just a message (no context).

  ## Parameters
  - `agent_name` - The name of the MindsDB agent to query
  - `message` - The user's message to send to the agent

  ## Returns
  - `{:ok, response}` - Success with agent response
  - `{:error, reason}` - Error with reason
  """
  def query_agent(agent_name, message) do
    query_agent(agent_name, message, "")
  end

  @doc """
  Tests the connection to MindsDB.

  ## Returns
  - `{:ok, status}` - Connection successful
  - `{:error, reason}` - Connection failed
  """
  def test_connection do
    # TODO: Implement actual MindsDB connection test
    {:ok, "MindsDB connection test successful"}
  end

  @doc """
  Gets the list of available agents.

  ## Returns
  - `{:ok, agents}` - List of available agent names
  - `{:error, reason}` - Error retrieving agents
  """
  def list_agents do
    # TODO: Implement actual MindsDB agent listing
    {:ok, ["the_grandmother", "the_robot", "the_farmer", "the_student", "the_alchemist", "the_hobo", "the_survivalist"]}
  end

  @doc """
  Gets information about a specific agent.

  ## Parameters
  - `agent_name` - The name of the agent

  ## Returns
  - `{:ok, agent_info}` - Agent information
  - `{:error, reason}` - Error retrieving agent info
  """
  def get_agent_info(agent_name) do
    # TODO: Implement actual MindsDB agent info retrieval
    {:ok, %{
      name: agent_name,
      status: "active",
      model: "gpt-3.5-turbo",
      created_at: DateTime.utc_now()
    }}
  end
end
