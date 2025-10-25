# check_openai.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== Checking MindsDB OpenAI Configuration ===")

# Check available ML handlers
case GreenManTavern.MindsDB.SQLClient.query("SHOW ML_ENGINES") do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Available ML Engines:")
    Enum.each(data, fn row ->
      if is_list(row) do
        engine_name = Enum.at(row, 0)
        engine_status = Enum.at(row, 1)
        IO.puts("   - #{engine_name}: #{engine_status}")
      end
    end)
    
  {:error, reason} ->
    IO.puts("❌ Failed to check ML engines: #{inspect(reason)}")
end

# Check if our models actually exist with DESCRIBE
IO.puts("\\n=== Checking Model Status ===")
case GreenManTavern.MindsDB.SQLClient.query("SHOW MODELS") do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Models in database:")
    Enum.each(data, fn row ->
      if is_list(row) and length(row) > 0 do
        model_name = Enum.at(row, 0)
        model_status = Enum.at(row, 5) || "unknown"
        IO.puts("   - #{model_name}: #{model_status}")
      end
    end)
    
  {:error, reason} ->
    IO.puts("❌ Failed to list models: #{inspect(reason)}")
end

# Try a different query approach for LLM models
IO.puts("\\n=== Testing Alternative Query Approach ===")
case GreenManTavern.MindsDB.SQLClient.query("SELECT * FROM mindsdb.models WHERE name = 'student_agent'") do
  {:ok, result} ->
    IO.puts("✅ Model exists in models table:")
    IO.inspect(result, limit: :infinity)
  {:error, reason} ->
    IO.puts("❌ Model not found in models table: #{inspect(reason)}")
end
