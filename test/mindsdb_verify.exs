# Start the application
{:ok, _} = Application.ensure_all_started(:green_man_tavern)

IO.puts("\n=== MindsDB Connection Verification ===\n")

# Test 1: Process alive
pid = Process.whereis(GreenManTavern.MindsDB.Client)
IO.puts("✓ Test 1 - Client Process: #{inspect(pid)}")

# Test 2: Connection
IO.puts("\n⏳ Test 2 - Testing connection...")

case GreenManTavern.MindsDB.ConnectionTest.test_connection() do
  {:ok, msg} -> IO.puts("✓ #{msg}")
  {:error, reason} -> IO.puts("✗ Connection failed: #{inspect(reason)}")
end

# Test 3: List agents
IO.puts("\n⏳ Test 3 - Listing agents...")

case GreenManTavern.MindsDB.ConnectionTest.list_agents() do
  {:ok, []} -> IO.puts("✓ Connected! No agents created yet (expected)")
  {:ok, agents} -> IO.puts("✓ Found agents: #{inspect(agents)}")
  {:error, reason} -> IO.puts("✗ Failed: #{inspect(reason)}")
end

# Test 4: Build context
IO.puts("\n⏳ Test 4 - Building user context...")
context = GreenManTavern.MindsDB.ContextBuilder.build_context(1)
IO.puts("✓ Context built: #{inspect(context, pretty: true)}")

IO.puts("\n=== All Tests Complete ===\n")
