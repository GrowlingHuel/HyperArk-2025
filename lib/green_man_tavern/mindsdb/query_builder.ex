defmodule GreenManTavern.MindsDB.QueryBuilder do
  @moduledoc """
  Helper module for building safe SQL queries for MindsDB agents.

  This module provides functions to construct parameterized SQL queries
  that prevent SQL injection and properly format context data for MindsDB.
  """

  require Logger

  @allowed_agents [
    "student_agent",
    "grandmother_agent",
    "farmer_agent",
    "robot_agent",
    "alchemist_agent",
    "survivalist_agent",
    "hobo_agent"
  ]

  @doc """
  Builds a safe SQL query for querying a MindsDB agent.

  ## Parameters
  - `agent_name` - The name of the MindsDB agent (must be in whitelist)
  - `message` - The user's message/question
  - `context` - A map containing user context data

  ## Returns
  - `{:ok, query_string}` - Safe SQL query string
  - `{:error, reason}` - Error if agent name is invalid

  ## Example
      iex> QueryBuilder.build_agent_query("student_agent", "What should I plant?", %{climate_zone: "8b"})
      {:ok, "SELECT response FROM mindsdb.student_agent WHERE question = $1 AND user_context = $2"}
  """
  def build_agent_query(agent_name, message, context \\ %{}) do
    with {:ok, safe_agent_name} <- validate_agent_name(agent_name),
         {:ok, _safe_message} <- sanitize_input(message),
         {:ok, _context_str} <- format_context_for_sql(context) do
      query = """
      SELECT response
      FROM mindsdb.#{safe_agent_name}
      WHERE question = $1
      AND user_context = $2
      """

      {:ok, query}
    else
      error -> error
    end
  end

  @doc """
  Builds a query with additional context parameters.

  This version allows for more complex queries with multiple context fields.
  """
  def build_agent_query_with_context(agent_name, message, context) do
    with {:ok, safe_agent_name} <- validate_agent_name(agent_name),
         {:ok, _safe_message} <- sanitize_input(message) do
      # Extract common context fields
      _user_location = Map.get(context, :user_location, "")
      _user_space = Map.get(context, :user_space, "")
      _user_skill = Map.get(context, :user_skill, "")
      _climate_zone = Map.get(context, :climate_zone, "")
      user_systems = Map.get(context, :user_systems, [])
      user_projects = Map.get(context, :user_projects, [])

      # Convert arrays to JSON strings
      _systems_str = Jason.encode!(user_systems)
      _projects_str = Jason.encode!(user_projects)

      query = """
      SELECT response
      FROM mindsdb.#{safe_agent_name}
      WHERE question = $1
      AND user_location = $2
      AND user_space = $3
      AND user_skill = $4
      AND climate_zone = $5
      AND user_systems = $6
      AND user_projects = $7
      """

      {:ok, query}
    else
      error -> error
    end
  end

  @doc """
  Sanitizes user input to prevent SQL injection.

  ## Parameters
  - `text` - The text to sanitize

  ## Returns
  - `{:ok, sanitized_text}` - Safe text for SQL queries
  - `{:error, reason}` - Error if text is invalid
  """
  def sanitize_input(text) when is_binary(text) do
    # Basic validation
    if String.length(text) > 2000 do
      {:error, "Message too long (max 2000 characters)"}
    else
      sanitized =
        text
        # Escape single quotes
        |> String.replace("'", "''")
        # Remove semicolons
        |> String.replace(";", "")
        # Remove SQL comments
        |> String.replace("--", "")
        # Remove block comments
        |> String.replace("/*", "")
        # Remove block comments
        |> String.replace("*/", "")
        |> String.trim()

      {:ok, sanitized}
    end
  end

  def sanitize_input(_), do: {:error, "Input must be a string"}

  @doc """
  Validates that the agent name is in the allowed whitelist.

  ## Parameters
  - `name` - The agent name to validate

  ## Returns
  - `{:ok, agent_name}` - Valid agent name
  - `{:error, reason}` - Error if agent name is invalid
  """
  def validate_agent_name(name) when is_binary(name) do
    if name in @allowed_agents do
      {:ok, name}
    else
      Logger.warning("Invalid agent name attempted: #{name}")
      {:error, "Invalid agent name: #{name}. Allowed: #{Enum.join(@allowed_agents, ", ")}"}
    end
  end

  def validate_agent_name(_), do: {:error, "Agent name must be a string"}

  @doc """
  Formats a context map for SQL injection into MindsDB queries.

  ## Parameters
  - `context_map` - A map containing user context data

  ## Returns
  - `{:ok, json_string}` - JSON-encoded context string
  - `{:error, reason}` - Error if context cannot be encoded
  """
  def format_context_for_sql(context_map) when is_map(context_map) do
    # Filter out nil values and convert to JSON
    filtered_context =
      context_map
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    case Jason.encode(filtered_context) do
      {:ok, json_str} -> {:ok, json_str}
      {:error, reason} -> {:error, "Failed to encode context: #{inspect(reason)}"}
    end
  end

  def format_context_for_sql(_), do: {:ok, "{}"}

  @doc """
  Gets the list of allowed agent names.
  """
  def get_allowed_agents, do: @allowed_agents

  @doc """
  Checks if an agent name is valid.
  """
  def valid_agent_name?(name), do: name in @allowed_agents

  @doc """
  Builds a simple test query for MindsDB connection testing.
  """
  def build_test_query do
    {:ok, "SELECT 1 as test"}
  end

  @doc """
  Builds a query to list all available MindsDB models/agents.
  """
  def build_list_agents_query do
    {:ok, "SHOW MODELS WHERE type = 'model'"}
  end

  @doc """
  Builds a query to get information about a specific agent.
  """
  def build_describe_agent_query(agent_name) do
    with {:ok, safe_name} <- validate_agent_name(agent_name) do
      {:ok, "DESCRIBE #{safe_name}"}
    else
      error -> error
    end
  end
end
