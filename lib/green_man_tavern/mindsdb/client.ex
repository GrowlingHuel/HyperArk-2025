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
          {:error, reason} -> {:error, reason}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("mindsdb.http_error", status: status, body: inspect(body))
        {:error, "MindsDB API error: #{status}"}

      {:error, %Mint.TransportError{} = err} ->
        Logger.error("mindsdb.transport_error", error: inspect(err))
        {:error, "HTTP transport error: #{inspect(err)}"}

      {:error, err} ->
        Logger.error("mindsdb.http_error", error: inspect(err))
        {:error, "HTTP request failed: #{inspect(err)}"}
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
      {:ok, %{"data" => data}} when is_list(data) and length(data) > 0 ->
        case data do
          # Format 1: List of strings (direct answer)
          [answer | _] when is_binary(answer) ->
            {:ok, answer}

          # Format 2: List of maps with "answer" key
          [%{"answer" => answer} | _] ->
            {:ok, answer}

          # Format 3: List of maps, take first value
          [first_map | _] when is_map(first_map) ->
            answer = first_map |> Map.values() |> List.first()
            {:ok, answer}

          _ ->
            {:error, "Unexpected data format: #{inspect(data)}"}
        end

      {:ok, %{"data" => []}} ->
        {:error, "No data returned from agent"}

      {:ok, %{"error" => error}} ->
        {:error, "MindsDB error: #{error}"}

      {:ok, response} ->
        {:error, "Unexpected response format: #{inspect(response)}"}

      {:error, error} ->
        {:error, "JSON decode error: #{inspect(error)}"}
    end
  end

  defp decode_body(%{"data" => _} = map), do: decode_body(Jason.encode!(map))

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
end
