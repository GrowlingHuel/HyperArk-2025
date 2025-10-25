# test_http_client.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("Testing HTTPClient.get_status...")
result = GreenManTavern.MindsDB.HTTPClient.get_status()
IO.inspect(result, label: "HTTPClient.get_status result")

IO.puts("Testing HTTPClient.query_sql...")
result2 = GreenManTavern.MindsDB.HTTPClient.query_sql("SELECT 'OK' as status")
IO.inspect(result2, label: "HTTPClient.query_sql result")
