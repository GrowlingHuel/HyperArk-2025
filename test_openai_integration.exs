# test_openai_integration.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== TESTING MINDSDB OPENAI INTEGRATION ===")

# First, let's check if there are any existing ML engines
IO.puts("\\n1. Checking available ML engines...")
engines_query = "SHOW ML_ENGINES;"

case GreenManTavern.MindsDB.SQLClient.query(engines_query) do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Available ML Engines:")

    Enum.each(data, fn [name, handler, connection_data] ->
      IO.puts("   - #{name}: #{handler}")
    end)

  {:error, reason} ->
    IO.puts("❌ Cannot query ML engines: #{inspect(reason)}")
end

# Test creating a model with simpler configuration
IO.puts("\\n2. Testing simplified model creation...")

# Drop any existing test models
drop_queries = [
  "DROP MODEL IF EXISTS mindsdb.simple_test;",
  "DROP MODEL IF EXISTS mindsDB.direct_openai_test;"
]

Enum.each(drop_queries, fn query ->
  GreenManTavern.MindsDB.SQLClient.query(query)
end)

# Try multiple different model creation approaches
test_models = [
  {
    "simple_test",
    """
    CREATE MODEL mindsdb.simple_test
    PREDICT response
    USING
      engine = 'openai',
      question_column = 'question',
      api_key = '#{System.get_env("OPENROUTER_API_KEY")}';
    """
  },
  {
    "direct_openai_test",
    """
    CREATE MODEL mindsdb.direct_openai_test
    PREDICT answer
    USING
      engine = 'openai',
      model_name = 'gpt-3.5-turbo',
      prompt_template = 'Answer this: {{question}}',
      api_key = '#{System.get_env("OPENROUTER_API_KEY")}',
      api_base = 'https://openrouter.ai/api/v1';
    """
  }
]

Enum.each(test_models, fn {model_name, create_query} ->
  IO.puts("\\n🔄 Creating #{model_name}...")

  case GreenManTavern.MindsDB.SQLClient.query(create_query) do
    {:ok, _} ->
      IO.puts("   ✅ #{model_name} creation command accepted")

      # Wait and test
      :timer.sleep(5000)

      test_query = "SELECT * FROM mindsdb.#{model_name} WHERE question = 'What is 2+2?';"
      IO.puts("   Testing #{model_name}...")

      case GreenManTavern.MindsDB.SQLClient.query(test_query) do
        {:ok, %{"data" => data}} when is_list(data) and length(data) > 0 ->
          IO.puts(
            "   🎉 #{model_name} WORKING! Response: #{inspect(Enum.at(Enum.at(data, 0), 0))}"
          )

        {:ok, result} ->
          IO.puts("   ⚠️ #{model_name} result: #{inspect(result)}")

        {:error, reason} ->
          IO.puts("   ❌ #{model_name} test failed: #{inspect(reason)}")
      end

    {:error, reason} ->
      IO.puts("   ❌ #{model_name} creation failed: #{inspect(reason)}")
  end
end)

# Check if models appear in any system tables
IO.puts("\\n3. Checking system information...")

system_queries = [
  {"All tables", "SHOW TABLES;"},
  {"All models", "SELECT * FROM mindsdb.models;"},
  {"Information schema",
   "SELECT table_name FROM information_schema.tables WHERE table_schema = 'mindsdb';"}
]

Enum.each(system_queries, fn {desc, query} ->
  IO.puts("\\n#{desc}:")

  case GreenManTavern.MindsDB.SQLClient.query(query) do
    {:ok, %{"data" => data}} ->
      IO.puts("   Found #{length(data)} items")

      Enum.each(Enum.take(data, 5), fn row ->
        IO.puts("   - #{inspect(row)}")
      end)

    {:error, reason} ->
      IO.puts("   Query failed: #{inspect(reason)}")
  end
end)
