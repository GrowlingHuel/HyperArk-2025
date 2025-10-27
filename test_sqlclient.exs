# test_sqlclient.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("Testing SQLClient (HTTP-based)...")

case GreenManTavern.MindsDB.SQLClient.query("SELECT 'OK' as status") do
  {:ok, result} ->
    IO.puts("✅ SUCCESS: SQLClient working via HTTP")
    IO.inspect(result, limit: :infinity)

  {:error, reason} ->
    IO.puts("❌ FAILED: #{inspect(reason)}")
end
