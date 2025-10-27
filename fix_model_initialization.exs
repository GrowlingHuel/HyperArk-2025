# fix_model_initialization.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== FIXING MODEL INITIALIZATION ===")

# Function to wait for model to be ready
defmodule ModelWaiter do
  def wait_for_model(model_name, max_attempts \\ 12) do
    IO.puts("   Waiting for #{model_name} to be ready...")
    wait_loop(model_name, 1, max_attempts)
  end

  defp wait_loop(_model_name, attempt, max_attempts) when attempt > max_attempts do
    IO.puts("   ❌ Model not ready after #{max_attempts} attempts")
    :timeout
  end

  defp wait_loop(model_name, attempt, max_attempts) do
    status_query = """
    SELECT name, status, error 
    FROM mindsdb.models 
    WHERE name = '#{model_name}';
    """

    case GreenManTavern.MindsDB.SQLClient.query(status_query) do
      {:ok, %{"data" => [[^model_name, status, error]]}} ->
        case status do
          "complete" ->
            IO.puts("   ✅ #{model_name} is ready! (attempt #{attempt})")
            :ready

          "error" ->
            IO.puts("   ❌ #{model_name} failed: #{error}")
            :error

          _ ->
            IO.puts("   ⏳ #{model_name} status: #{status} (attempt #{attempt}/#{max_attempts})")
            :timer.sleep(5000)
            wait_loop(model_name, attempt + 1, max_attempts)
        end

      _ ->
        IO.puts("   ⏳ #{model_name} not found yet (attempt #{attempt}/#{max_attempts})")
        :timer.sleep(5000)
        wait_loop(model_name, attempt + 1, max_attempts)
    end
  end
end

# Recreate models with proper waiting
agents = [
  "student_agent",
  "grandmother_agent",
  "farmer_agent",
  "robot_agent",
  "alchemist_agent",
  "survivalist_agent",
  "hobo_agent"
]

Enum.each(agents, fn agent_name ->
  IO.puts("\\n🔄 Processing #{agent_name}...")

  # Drop if exists
  drop_query = "DROP MODEL IF EXISTS mindsdb.#{agent_name};"
  {:ok, _} = GreenManTavern.MindsDB.SQLClient.query(drop_query)

  # Get the original prompt
  agent_config = GreenManTavern.MindsDB.AgentInstaller.get_agent_config(agent_name)
  prompt = agent_config.prompt

  # Create with proper escaping
  safe_prompt = String.replace(prompt, "'", "''")

  create_agent = """
  CREATE MODEL mindsdb.#{agent_name}
  PREDICT answer
  USING
    engine = 'openai',
    model_name = 'gpt-3.5-turbo',
    prompt_template = '#{safe_prompt}',
    openai_api_key = '#{System.get_env("OPENROUTER_API_KEY")}',
    openai_api_base = 'https://openrouter.ai/api/v1';
  """

  case GreenManTavern.MindsDB.SQLClient.query(create_agent) do
    {:ok, _} ->
      IO.puts("   ✅ #{agent_name} creation command accepted")

      # Wait for model to be ready
      case ModelWaiter.wait_for_model(agent_name) do
        :ready ->
          # Test the model
          test_query =
            "SELECT answer FROM mindsdb.#{agent_name} WHERE question = 'Hello, how are you?';"

          case GreenManTavern.MindsDB.SQLClient.query(test_query) do
            {:ok, %{"data" => data}} when is_list(data) and length(data) > 0 ->
              IO.puts("   🎉 #{agent_name} TEST SUCCESSFUL!")
              IO.puts("   Response: #{inspect(Enum.at(Enum.at(data, 0), 0))}")

            {:ok, result} ->
              IO.puts("   ⚠️ #{agent_name} test returned: #{inspect(result)}")

            {:error, reason} ->
              IO.puts("   ❌ #{agent_name} test failed: #{inspect(reason)}")
          end

        _ ->
          IO.puts("   ⚠️ #{agent_name} not ready for testing")
      end

    {:error, reason} ->
      IO.puts("   ❌ #{agent_name} creation failed: #{inspect(reason)}")
  end
end)

IO.puts("\\n=== FINAL VERIFICATION ===")
# Final comprehensive test
test_agent = "student_agent"

final_test =
  "SELECT answer FROM mindsdb.#{test_agent} WHERE question = 'What is permaculture and why is it important?';"

case GreenManTavern.MindsDB.SQLClient.query(final_test) do
  {:ok, %{"data" => data}} when is_list(data) and length(data) > 0 ->
    IO.puts("🎉 ULTIMATE SUCCESS! Agents are working!")
    IO.puts("Sample response from #{test_agent}:")
    IO.puts("  #{inspect(Enum.at(Enum.at(data, 0), 0))}")

  {:ok, result} ->
    IO.puts("Final test result: #{inspect(result)}")

  {:error, reason} ->
    IO.puts("Final test failed: #{inspect(reason)}")
end
