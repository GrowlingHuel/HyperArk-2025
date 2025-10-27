defmodule GreenManTavern.MindsDB.SQLClient do
  @moduledoc """
  SQL client for MindsDB - uses HTTP API as primary method
  """

  alias GreenManTavern.MindsDB.HTTPClient

  @doc """
  Execute SQL query via MindsDB HTTP API
  """
  def query(sql, params \\ []) do
    # Replace parameter placeholders with actual values
    sql_with_params = replace_params(sql, params)

    # Use HTTP client - it's more reliable with MindsDB
    HTTPClient.query_sql(sql_with_params)
  end

  @doc """
  List available models.
  """
  def list_models do
    HTTPClient.query_sql("SHOW MODELS")
  end

  @doc """
  Drop a model.
  """
  def drop_model(model_name) do
    HTTPClient.query_sql("DROP MODEL #{model_name}")
  end

  defp replace_params(sql, []) do
    sql
  end

  defp replace_params(sql, params) do
    # Simple parameter replacement
    Enum.reduce(params, {sql, 0}, fn param, {sql_acc, index} ->
      placeholder = "?"

      replacement =
        case param do
          str when is_binary(str) -> "'#{String.replace(str, "'", "''")}'"
          other -> to_string(other)
        end

      new_sql = String.replace(sql_acc, placeholder, replacement, global: false)
      {new_sql, index + 1}
    end)
    |> elem(0)
  end
end
