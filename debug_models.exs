# debug_models.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== COMPREHENSIVE MODEL DEBUGGING ===")

# 1. Check exact model status
IO.puts("1. Checking detailed model status...")
status_query = """
SELECT name, engine, status, error, active, version, project 
FROM mindsdb.models 
WHERE name LIKE '%agent%' OR name LIKE '%test%';
"""

case GreenManTavern.MindsDB.SQLClient.query(status_query) do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Model status query successful")
    if Enum.empty?(data) do
      IO.puts("   No models found with 'agent' or 'test' in name")
    else
      IO.puts("   Found #{length(data)} models:")
      Enum.each(data, fn row ->
        IO.puts("   - #{Enum.at(row, 0)}: engine=#{Enum.at(row, 1)}, status=#{Enum.at(row, 2)}, error=#{Enum.at(row, 3)}")
      end)
    end
  {:error, reason} ->
    IO.puts("❌ Model status query failed: #{inspect(reason)}")
end

# 2. Check if models exist in information_schema
IO.puts("\\n2. Checking information_schema.tables...")
tables_query = """
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'mindsdb' 
  AND (table_name LIKE '%agent%' OR table_name LIKE '%test%');
"""

case GreenManTavern.MindsDB.SQLClient.query(tables_query) do
  {:ok, %{"data" => data}} ->
    IO.puts("✅ Tables query successful")
    if Enum.empty?(data) do
      IO.puts("   No tables found with 'agent' or 'test' in name")
    else
      IO.puts("   Found #{length(data)} tables:")
      Enum.each(data, fn row ->
        IO.puts("   - #{Enum.at(row, 0)}: #{Enum.at(row, 1)}")
      end)
    end
  {:error, reason} ->
    IO.puts("❌ Tables query failed: #{inspect(reason)}")
end

# 3. Test a completely different model creation approach
IO.puts("\\n3. Testing alternative model creation...")
# First, drop any existing test model
drop_query = "DROP MODEL IF EXISTS mindsdb.debug_test_model;"
GreenManTavern.MindsDB.SQLClient.query(drop_query)

# Create with explicit model_name parameter (this worked before)
create_debug_query = """
CREATE MODEL mindsdb.debug_test_model
PREDICT answer
USING
  engine = 'openai',
  model_name = 'gpt-3.5-turbo',
  prompt_template = 'Answer this question about gardening: {{question}}',
  openai_api_key = '#{System.get_env("OPENROUTER_API_KEY")}',
  openai_api_base = 'https://openrouter.ai/api/v1';
"""

case GreenManTavern.MindsDB.SQLClient.query(create_debug_query) do
  {:ok, _} ->
    IO.puts("✅ Debug model created successfully!")
    
    # Wait for model to initialize
    IO.puts("   Waiting 10 seconds for model initialization...")
    :timer.sleep(10000)
    
    # Test with the exact syntax that worked before
    IO.puts("   Testing debug model...")
    test_debug_query = """
    SELECT answer 
    FROM mindsdb.debug_test_model
    WHERE question = 'What is composting?';
    """
    
    case GreenManTavern.MindsDB.SQLClient.query(test_debug_query) do
      {:ok, result} ->
        IO.puts("🎉 DEBUG MODEL WORKING!")
        IO.inspect(result, limit: :infinity)
        
        # If this works, recreate all agents with this approach
        IO.puts("\\n4. Recreating all agents with working approach...")
        agents = ["student_agent", "grandmother_agent", "farmer_agent", "robot_agent", "alchemist_agent", "survivalist_agent", "hobo_agent"]
        
        Enum.each(agents, fn agent_name ->
          drop_agent = "DROP MODEL IF EXISTS mindsdb.#{agent_name};"
          GreenManTavern.MindsDB.SQLClient.query(drop_agent)
          
          # Get the original prompt
          agent_config = GreenManTavern.MindsDB.AgentInstaller.get_agent_config(agent_name)
          prompt = agent_config.prompt
          
          create_agent = """
          CREATE MODEL mindsdb.#{agent_name}
          PREDICT answer
          USING
            engine = 'openai',
            model_name = 'gpt-3.5-turbo', 
            prompt_template = '#{String.replace(prompt, "'", "''")}',
            openai_api_key = '#{System.get_env("OPENROUTER_API_KEY")}',
            openai_api_base = 'https://openrouter.ai/api/v1';
          """
          
          case GreenManTavern.MindsDB.SQLClient.query(create_agent) do
            {:ok, _} -> IO.puts("   ✅ #{agent_name} recreated")
            {:error, reason} -> IO.puts("   ❌ #{agent_name} failed: #{inspect(reason)}")
          end
        end)
        
        IO.puts("\\n🎉 All agents recreated with working approach!")
        IO.puts("   Waiting 15 seconds for all models to initialize...")
        :timer.sleep(15000)
        
        # Test one agent
        IO.puts("   Final test of student_agent...")
        final_test = "SELECT answer FROM mindsdb.student_agent WHERE question = 'What is permaculture?';"
        case GreenManTavern.MindsDB.SQLClient.query(final_test) do
          {:ok, final_result} ->
            IO.puts("🎉 PERMANENT SUCCESS!")
            IO.inspect(final_result, limit: :infinity)
          {:error, final_reason} ->
            IO.puts("❌ Final test failed: #{inspect(final_reason)}")
        end
        
      {:error, debug_reason} ->
        IO.puts("❌ Debug model test failed: #{inspect(debug_reason)}")
        IO.puts("   This suggests the issue is with model initialization or API configuration")
    end
    
  {:error, create_reason} ->
    IO.puts("❌ Debug model creation failed: #{inspect(create_reason)}")
    IO.puts("   This suggests the API configuration is the issue")
end

# 4. Check MindsDB version and capabilities
IO.puts("\\n5. Checking MindsDB version and capabilities...")
version_query = "SELECT @@version;"
case GreenManTavern.MindsDB.SQLClient.query(version_query) do
  {:ok, %{"data" => [[version]]}} ->
    IO.puts("   MindsDB Version: #{version}")
  _ ->
    IO.puts("   Could not determine MindsDB version")
end
