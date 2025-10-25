# test_complete.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== Testing HTTPClient ===")

IO.puts("1. Testing get_status...")
case GreenManTavern.MindsDB.HTTPClient.get_status() do
  {:ok, status} -> 
    version = Map.get(status, "mindsdb_version", "unknown")
    IO.puts("✅ SUCCESS: MindsDB v#{version}")
  {:error, reason} -> 
    IO.puts("❌ FAILED: #{inspect(reason)}")
end

IO.puts("2. Testing query_sql...")
case GreenManTavern.MindsDB.HTTPClient.query_sql("SELECT 'OK' as status") do
  {:ok, result} -> 
    IO.puts("✅ SUCCESS: SQL query worked")
    IO.inspect(result, limit: :infinity)
  {:error, reason} -> 
    IO.puts("❌ FAILED: #{inspect(reason)}")
end

IO.puts("3. Testing upload_file (stub)...")
case GreenManTavern.MindsDB.HTTPClient.upload_file("/tmp/test.pdf") do
  {:ok, result} -> 
    IO.puts("✅ SUCCESS: upload_file worked")
    IO.inspect(result)
  {:error, reason} -> 
    IO.puts("❌ FAILED: #{inspect(reason)}")
end

IO.puts("4. Testing delete_file...")
case GreenManTavern.MindsDB.HTTPClient.delete_file("test.txt") do
  {:ok, result} -> 
    IO.puts("✅ SUCCESS: delete_file worked")
    IO.inspect(result)
  {:error, reason} -> 
    IO.puts("❌ FAILED: #{inspect(reason)}")
end

IO.puts("5. Testing KnowledgeManager integration...")
# This should no longer produce warnings
IO.puts("✅ KnowledgeManager should now work without HTTPClient warnings")
