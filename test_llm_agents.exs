# test_llm_agents.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== Testing LLM Agent Queries ===")

# Method 1: JOIN syntax (recommended for LLM models)
IO.puts("1. Testing JOIN syntax...")
join_query = """
SELECT m.answer
FROM mindsdb.student_agent AS m
WHERE m.question = 'What is permaculture?'
"""

case GreenManTavern.MindsDB.SQLClient.query(join_query) do
  {:ok, result} ->
    IO.puts("✅ JOIN syntax successful!")
    IO.inspect(result, limit: :infinity)
  {:error, reason} ->
    IO.puts("❌ JOIN syntax failed: #{inspect(reason)}")
    
    # Method 2: Check model status
    IO.puts("2. Checking model training status...")
    status_query = "SELECT * FROM mindsdb.models WHERE name = 'student_agent'"
    case GreenManTavern.MindsDB.SQLClient.query(status_query) do
      {:ok, status_result} ->
        IO.puts("✅ Model status:")
        IO.inspect(status_result, limit: :infinity)
      {:error, status_reason} ->
        IO.puts("❌ Failed to check status: #{inspect(status_reason)}")
    end
    
    # Method 3: Try different model types
    IO.puts("3. Testing with simpler model...")
    simple_query = """
    CREATE MODEL IF NOT EXISTS test_chat_model
    PREDICT answer
    USING
      engine = 'openai',
      model_name = 'gpt-3.5-turbo',
      prompt_template = 'Answer this question: {{question}}';
    """
    
    case GreenManTavern.MindsDB.SQLClient.query(simple_query) do
      {:ok, _} ->
        IO.puts("✅ Simple model created, testing query...")
        :timer.sleep(5000)
        
        test_simple = """
        SELECT m.answer
        FROM mindsdb.test_chat_model AS m
        WHERE m.question = 'Hello, what is your name?'
        """
        
        case GreenManTavern.MindsDB.SQLClient.query(test_simple) do
          {:ok, simple_result} ->
            IO.puts("✅ Simple model query successful!")
            IO.inspect(simple_result, limit: :infinity)
          {:error, simple_reason} ->
            IO.puts("❌ Simple model query failed: #{inspect(simple_reason)}")
        end
        
      {:error, create_reason} ->
        IO.puts("❌ Failed to create simple model: #{inspect(create_reason)}")
    end
end
