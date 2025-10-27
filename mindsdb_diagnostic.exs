# mindsdb_diagnostic.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== MINDSDB DIAGNOSTIC ===")

# Check what models actually exist
IO.puts("\\n1. Checking all models in MindsDB...")
models_query = "SELECT name, engine, status FROM mindsdb.models;"

case GreenManTavern.MindsDB.SQLClient.query(models_query) do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Found #{length(data)} total models:")

    Enum.each(data, fn [name, engine, status] ->
      IO.puts("   - #{name}: #{engine} (#{status})")
    end)

  {:error, reason} ->
    IO.puts("❌ Cannot query models: #{inspect(reason)}")
end

# Check what tables exist
IO.puts("\\n2. Checking all tables...")
tables_query = "SHOW TABLES;"

case GreenManTavern.MindsDB.SQLClient.query(tables_query) do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Found #{length(data)} tables:")

    Enum.each(data, fn [table_name] ->
      IO.puts("   - #{table_name}")
    end)

  {:error, reason} ->
    IO.puts("❌ Cannot query tables: #{inspect(reason)}")
end

# Test basic query capability
IO.puts("\\n3. Testing basic query...")
test_query = "SELECT 1 as test;"

case GreenManTavern.MindsDB.SQLClient.query(test_query) do
  {:ok, result} ->
    IO.puts("✅ Basic query working: #{inspect(result)}")

  {:error, reason} ->
    IO.puts("❌ Basic query failed: #{inspect(reason)}")
end
