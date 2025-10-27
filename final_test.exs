# final_test.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== FINAL COMPREHENSIVE TEST ===")

IO.puts("1. Testing HTTPClient.get_status...")

case GreenManTavern.MindsDB.HTTPClient.get_status() do
  {:ok, status} ->
    version = Map.get(status, "mindsdb_version", "unknown")
    IO.puts("✅ HTTPClient.get_status: MindsDB v#{version}")

  {:error, reason} ->
    IO.puts("❌ HTTPClient.get_status failed: #{inspect(reason)}")
end

IO.puts("2. Testing SQLClient.query...")

case GreenManTavern.MindsDB.SQLClient.query("SELECT 'SUCCESS' as test_status") do
  {:ok, result} ->
    IO.puts("✅ SQLClient.query: HTTP-based SQL working")

  {:error, reason} ->
    IO.puts("❌ SQLClient.query failed: #{inspect(reason)}")
end

IO.puts("3. Testing SQLClient.list_models...")

case GreenManTavern.MindsDB.SQLClient.list_models() do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ SQLClient.list_models: #{length(data)} models found")

  {:error, reason} ->
    IO.puts("❌ SQLClient.list_models failed: #{inspect(reason)}")
end

IO.puts("4. Testing KnowledgeManager file operations...")

case GreenManTavern.MindsDB.HTTPClient.upload_file("/tmp/test.pdf") do
  {:ok, result} ->
    IO.puts("✅ HTTPClient.upload_file: File operations working")

  {:error, reason} ->
    IO.puts("❌ HTTPClient.upload_file failed: #{inspect(reason)}")
end

IO.puts("=== ALL TESTS COMPLETE ===")
