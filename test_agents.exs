# test_agents.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== Testing Agent Installation ===")

# First, let's check if agents exist in MindsDB
IO.puts("1. Checking if agents exist in MindsDB...")
case GreenManTavern.MindsDB.SQLClient.list_models() do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Models in MindsDB:")
    Enum.each(data, fn row ->
      if is_list(row) do
        model_name = List.first(row)
        if is_binary(model_name) do
          IO.puts("   - #{model_name}")
        end
      end
    end)
    
  {:error, reason} ->
    IO.puts("❌ Failed to list models: #{inspect(reason)}")
end

# Test a simple query to one agent
IO.puts("2. Testing direct query to student_agent...")
query = "SELECT answer FROM student_agent WHERE question = 'Hello, who are you?'"
case GreenManTavern.MindsDB.SQLClient.query(query) do
  {:ok, result} ->
    IO.puts("✅ Student agent query successful!")
    IO.inspect(result, limit: :infinity)
    
  {:error, reason} ->
    IO.puts("❌ Student agent query failed: #{inspect(reason)}")
    
    # Let's check what the actual error is
    IO.puts("3. Checking agent creation status...")
    case GreenManTavern.MindsDB.SQLClient.query("DESCRIBE student_agent") do
      {:ok, desc_result} ->
        IO.puts("✅ Student agent exists with description:")
        IO.inspect(desc_result, limit: :infinity)
      {:error, desc_error} ->
        IO.puts("❌ Cannot describe student_agent: #{inspect(desc_error)}")
    end
end
