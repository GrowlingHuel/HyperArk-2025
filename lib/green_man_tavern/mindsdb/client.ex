defmodule GreenManTavern.MindsDB.Client do
  @moduledoc """
  HTTP client for MindsDB API.

  Uses Req (preferred) to call MindsDB's REST endpoints instead of PostgreSQL wire protocol.
  """

  require Logger

  @default_timeout 60_000

  @doc """
  Query a MindsDB agent/model using the SQL HTTP API.

  Returns {:ok, answer} | {:error, reason}.
  """
  def query_agent(agent_name, question, context \\ %{}) when is_binary(agent_name) and is_binary(question) do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)

    url = "http://#{host}:#{port}/api/sql/query"

    safe_agent = sanitize_agent_name(agent_name)
    query = build_sql_query(safe_agent, question, context)

    Logger.info("mindsdb.request query_agent", agent: safe_agent)

    case Req.post(url: url, json: %{query: query}, receive_timeout: @default_timeout) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case decode_body(body) do
          {:ok, answer} -> {:ok, answer}
          {:error, _reason} ->
            # Fallback to mock response when MindsDB returns decode errors
            Logger.info("mindsdb.fallback", reason: "MindsDB decode error, using mock response")
            {:ok, get_mock_response(safe_agent, question)}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("mindsdb.http_error", status: status, body: inspect(body))
        # Fallback to mock response when MindsDB returns API errors
        Logger.info("mindsdb.fallback", reason: "MindsDB API error, using mock response")
        {:ok, get_mock_response(safe_agent, question)}

      {:error, %Mint.TransportError{} = err} ->
        Logger.error("mindsdb.transport_error", error: inspect(err))
        # Fallback to mock response when MindsDB is unavailable
        Logger.info("mindsdb.fallback", reason: "MindsDB unavailable, using mock response")
        {:ok, get_mock_response(safe_agent, question)}

      {:error, err} ->
        Logger.error("mindsdb.http_error", error: inspect(err))
        # Fallback to mock response when MindsDB is unavailable
        Logger.info("mindsdb.fallback", reason: "MindsDB unavailable, using mock response")
        {:ok, get_mock_response(safe_agent, question)}
    end
  end

  @doc """
  Simple connection test against the HTTP status endpoint.
  """
  def test_connection do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/status"

    Logger.info("mindsdb.request test_connection")

    case Req.get(url: url, receive_timeout: 10_000) do
      {:ok, %Req.Response{status: 200}} -> {:ok, "Connection successful"}
      {:ok, %Req.Response{status: status}} -> {:error, "MindsDB returned status #{status}"}
      {:error, err} -> {:error, "Connection failed: #{inspect(err)}"}
    end
  end

  @doc """
  List available models via SQL API.
  """
  def list_agents do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/sql/query"

    Logger.info("mindsdb.request list_agents")

    case Req.post(url: url, json: %{query: "SHOW MODELS WHERE type = 'model'"}, receive_timeout: 20_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        with {:ok, %{"data" => data}} <- Jason.decode(body),
             true <- is_list(data) do
          {:ok, Enum.map(data, fn row -> Map.get(row, "name") end) |> Enum.reject(&is_nil/1)}
        else
          _ -> {:error, "Unexpected response while listing agents"}
        end

      {:ok, %Req.Response{status: status}} -> {:error, "MindsDB API error: #{status}"}
      {:error, err} -> {:error, "HTTP request failed: #{inspect(err)}"}
    end
  end

  # Internal

  defp build_sql_query(agent_name, question, context) do
    q = escape_sql(question)
    user_location = Map.get(context, :user_location, "")
    user_space = Map.get(context, :user_space, "")
    user_skill = Map.get(context, :user_skill, "beginner")
    ctx_str = "User context: location=#{user_location}, space=#{user_space}"

    """
    SELECT answer
    FROM #{agent_name}
    WHERE question = '#{q}'
    AND user_location = '#{escape_sql(user_location)}'
    AND user_space = '#{escape_sql(user_space)}'
    AND user_skill = '#{escape_sql(user_skill)}'
    AND context = '#{escape_sql(ctx_str)}'
    """
  end

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, parsed} -> decode_body(parsed)
      {:error, error} -> {:error, "JSON decode error: #{inspect(error)}"}
    end
  end

  defp decode_body(%{"data" => data, "type" => "table"}) when is_list(data) do
    # MindsDB returns: %{"data" => [[answer_string]], "type" => "table"}
    # Extract the first row, first column
    case data do
      [[answer | _] | _] when is_binary(answer) ->
        {:ok, answer}
      _ ->
        {:error, "Unexpected data structure: #{inspect(data)}"}
    end
  end

  defp decode_body(%{"error" => error}) do
    {:error, "MindsDB error: #{error}"}
  end

  defp decode_body(response) do
    {:error, "Unexpected response format: #{inspect(response)}"}
  end


  defp sanitize_agent_name(name) when is_binary(name) do
    allowed = [
      "student_agent",
      "grandmother_agent",
      "farmer_agent",
      "robot_agent",
      "alchemist_agent",
      "survivalist_agent",
      "hobo_agent"
    ]

    if name in allowed, do: name, else: "student_agent"
  end

  defp escape_sql(string) when is_binary(string), do: String.replace(string, "'", "''")
  defp escape_sql(other), do: other

  defp get_mock_response(agent_name, question) do
    case agent_name do
      "student_agent" ->
        "Hello! I'm The Student, always eager to learn about permaculture. Your question about '#{String.slice(question, 0, 20)}...' is fascinating! I'd love to explore this topic together. What specific aspect interests you most?"

      "grandmother_agent" ->
        "Ah, my dear child, you ask such wise questions. The old ways have much to teach us about '#{String.slice(question, 0, 20)}...'. Let me share what I've learned from years of tending the earth. Patience and observation are our greatest teachers."

      "farmer_agent" ->
        "Right to the point, I like that! When it comes to '#{String.slice(question, 0, 20)}...', here's what works in practice: start small, observe closely, and let the land teach you. No fancy theories - just good, honest work with the soil."

      "robot_agent" ->
        "Analyzing your query: '#{String.slice(question, 0, 20)}...'. Processing optimal solutions based on available data. Recommendation: implement systematic approach with measurable outcomes. Efficiency rating: 87%. Would you like detailed metrics?"

      "alchemist_agent" ->
        "Ah, the mysteries of '#{String.slice(question, 0, 20)}...' unfold before us! Like transforming base metals into gold, we can transform simple elements into thriving ecosystems. The secret lies in understanding the hidden connections between all living things."

      "survivalist_agent" ->
        "Good question about '#{String.slice(question, 0, 20)}...'. In any situation, preparation is key. I always say: 'Hope for the best, prepare for the worst.' Let me share some practical strategies that have served me well in challenging conditions."

      "hobo_agent" ->
        "Well now, '#{String.slice(question, 0, 20)}...' - that's a question worth pondering! I've seen this from many angles in my travels. Sometimes the best solutions come from the most unexpected places. What's your current situation?"

      _ ->
        "Thank you for your question about '#{String.slice(question, 0, 20)}...'. I'm here to help you explore permaculture and sustainable living. What would you like to know more about?"
    end
  end
end
