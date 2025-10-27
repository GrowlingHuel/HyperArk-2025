defmodule GreenManTavern.MindsDB.HTTPClient do
  @moduledoc """
  HTTP client for MindsDB REST API.

  Provides functions to interact with MindsDB via its HTTP API on port 47334.
  """

  require Logger

  @default_timeout 30_000

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

  @doc """
  List available models.
  """
  def list_models do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/sql/query"

    Logger.info("mindsdb.request list_models")

    case Req.post(url: url, json: %{query: "SHOW MODELS"}, receive_timeout: @default_timeout) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("mindsdb.list_models_error", status: status, body: inspect(body))
        {:error, {:http_error, status, body}}

      {:error, err} ->
        Logger.error("mindsdb.list_models_connection_error", error: inspect(err))
        {:error, err}
    end
  end

  @doc """
  Get details for a specific model.
  """
  def get_model(model_name) do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/sql/query"

    Logger.info("mindsdb.request get_model", model: model_name)

    case Req.post(
           url: url,
           json: %{query: "DESCRIBE #{model_name}"},
           receive_timeout: @default_timeout
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("mindsdb.get_model_error", status: status, body: inspect(body))
        {:error, {:http_error, status, body}}

      {:error, err} ->
        Logger.error("mindsdb.get_model_connection_error", error: inspect(err))
        {:error, err}
    end
  end

  @doc """
  List uploaded files.
  """
  def list_files do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/sql/query"

    Logger.info("mindsdb.request list_files")

    case Req.post(url: url, json: %{query: "SHOW FILES"}, receive_timeout: @default_timeout) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("mindsdb.list_files_error", status: status, body: inspect(body))
        {:error, {:http_error, status, body}}

      {:error, err} ->
        Logger.error("mindsdb.list_files_connection_error", error: inspect(err))
        {:error, err}
    end
  end

  @doc """
  Execute SQL query via HTTP API.
  """
  def query_sql(sql) do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/sql/query"

    Logger.info("mindsdb.request query_sql", query: String.slice(sql, 0, 100))

    case Req.post(url: url, json: %{query: sql}, receive_timeout: @default_timeout) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("mindsdb.query_sql_error", status: status, body: inspect(body))
        {:error, {:http_error, status, body}}

      {:error, err} ->
        Logger.error("mindsdb.query_sql_connection_error", error: inspect(err))
        {:error, err}
    end
  end

  @doc """
  Upload file to MindsDB (stub implementation)
  """
  def upload_file(file_path, metadata \\ %{}) do
    Logger.info("mindsdb.upload_file", file_path: file_path, metadata: metadata)
    # TODO: Implement actual file upload to MindsDB
    {:ok, %{"filename" => Path.basename(file_path), "status" => "uploaded"}}
  end

  @doc """
  Delete file from MindsDB (stub implementation)
  """
  def delete_file(filename) do
    host = Application.get_env(:green_man_tavern, :mindsdb_host, "localhost")
    port = Application.get_env(:green_man_tavern, :mindsdb_http_port, 47_334)
    url = "http://#{host}:#{port}/api/files/#{filename}"

    Logger.info("mindsdb.delete_file", filename: filename)

    case Req.delete(url: url) do
      {:ok, %Req.Response{status: 200}} -> {:ok, "deleted"}
      {:ok, %Req.Response{status: 404}} -> {:ok, "not_found"}
      {:ok, %Req.Response{status: status}} -> {:error, "HTTP #{status}"}
      {:error, err} -> {:error, err}
    end
  end
end
