# Read the current file
content = File.read!("lib/green_man_tavern/mindsdb/http_client.ex")

# Replace the get_status function
fixed_content = String.replace(content, ~S"""
  @doc """
  Get MindsDB server status.
  """
  def get_status do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/status"

    Logger.info("mindsdb.request get_status")

    case Req.get(url: url, receive_timeout: 10_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, status} -> {:ok, status}
          {:error, error} -> {:error, "JSON decode error: #{inspect(error)}"}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, "MindsDB returned status #{status}"}

      {:error, err} ->
        {:error, "Connection failed: #{inspect(err)}"}
    end
  end
""", ~S"""
  @doc """
  Get MindsDB server status.
  """
  def get_status do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/status"

    Logger.info("mindsdb.request get_status")

    case Req.get(url: url, receive_timeout: 10_000, decode_body: false) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, status} -> {:ok, status}
          {:error, error} -> {:error, "JSON decode error: #{inspect(error)}"}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, "MindsDB returned status #{status}"}

      {:error, err} ->
        {:error, "Connection failed: #{inspect(err)}"}
    end
  end
""")

# Write the fixed content back
File.write!("lib/green_man_tavern/mindsdb/http_client.ex", fixed_content)
