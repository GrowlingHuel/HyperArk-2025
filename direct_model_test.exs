# direct_model_test.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== DIRECT MODEL TESTING APPROACH ===")

# Test if models are queryable directly, regardless of status table
defmodule DirectTester do
  def test_model_immediately(model_name, question, max_attempts \\ 10) do
    IO.puts("\\n🔄 Testing #{model_name} immediately...")
    test_loop(model_name, question, 1, max_attempts)
  end

  defp test_loop(model_name, question, attempt, max_attempts) when attempt > max_attempts do
    IO.puts("   ❌ #{model_name} not queryable after #{max_attempts} attempts")
    :timeout
  end

  defp test_loop(model_name, question, attempt, max_attempts) do
    safe_question = String.replace(question, "'", "''")
    query = "SELECT answer FROM mindsdb.#{model_name} WHERE question = '#{safe_question}';"

    case GreenManTavern.MindsDB.SQLClient.query(query) do
      {:ok, %{"data" => data}} when is_list(data) and length(data) > 0 ->
        answer = Enum.at(Enum.at(data, 0), 0)
        IO.puts("   ✅ #{model_name} SUCCESS on attempt #{attempt}!")
        IO.puts("   Response: #{String.slice(inspect(answer), 0, 150)}...")
        {:ok, answer}

      {:ok, %{"type" => "error", "error_message" => error_msg}} ->
        if String.contains?(error_msg, "not found") or
             String.contains?(error_msg, "does not exist") do
          IO.puts("   ⏳ #{model_name} not ready yet (attempt #{attempt}/#{max_attempts})")
          :timer.sleep(3000)
          test_loop(model_name, question, attempt + 1, max_attempts)
        else
          IO.puts("   ❌ #{model_name} error: #{error_msg}")
          {:error, error_msg}
        end

      {:ok, result} ->
        IO.puts("   ⚠️ #{model_name} unexpected result: #{inspect(result)}")
        :timer.sleep(3000)
        test_loop(model_name, question, attempt + 1, max_attempts)

      {:error, reason} ->
        IO.puts(
          "   ⏳ #{model_name} connection issue (attempt #{attempt}/#{max_attempts}): #{inspect(reason)}"
        )

        :timer.sleep(3000)
        test_loop(model_name, question, attempt + 1, max_attempts)
    end
  end
end

# Create and test one model at a time with proper waiting
test_cases = [
  {"student_agent", "What are three key principles of permaculture?"},
  {"grandmother_agent", "How do I start a small kitchen garden?"},
  {"farmer_agent", "What's the best way to improve clay soil?"}
]

Enum.each(test_cases, fn {agent_name, question} ->
  IO.puts("\\n" <> String.duplicate("=", 50))
  IO.puts("PROCESSING: #{agent_name}")
  IO.puts(String.duplicate("=", 50))

  # Drop if exists
  drop_query = "DROP MODEL IF EXISTS mindsdb.#{agent_name};"
  {:ok, _} = GreenManTavern.MindsDB.SQLClient.query(drop_query)
  IO.puts("✅ Dropped existing #{agent_name}")

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
      IO.puts("✅ #{agent_name} creation command accepted")
      IO.puts("⏳ Waiting 10 seconds for initial model setup...")
      :timer.sleep(10000)

      # Test directly without checking status table
      case DirectTester.test_model_immediately(agent_name, question) do
        {:ok, _answer} ->
          IO.puts("🎉 #{agent_name} IS WORKING!")

        _ ->
          IO.puts("⚠️ #{agent_name} may need more time or has issues")
      end

    {:error, reason} ->
      IO.puts("❌ #{agent_name} creation failed: #{inspect(reason)}")
  end
end)

IO.puts("\\n" <> String.duplicate("=", 50))
IO.puts("FINAL SYSTEM STATUS")
IO.puts(String.duplicate("=", 50))

# Final comprehensive test
final_test_query =
  "SELECT answer FROM mindsdb.student_agent WHERE question = 'What is permaculture?';"

case GreenManTavern.MindsDB.SQLClient.query(final_test_query) do
  {:ok, %{"data" => data}} when is_list(data) and length(data) > 0 ->
    IO.puts("🎉 ULTIMATE SUCCESS! Green Man Tavern is OPERATIONAL!")
    IO.puts("Student Agent Response: #{inspect(Enum.at(Enum.at(data, 0), 0))}")

  {:ok, result} ->
    IO.puts("Final test result: #{inspect(result)}")

  {:error, reason} ->
    IO.puts("Final test failed: #{inspect(reason)}")
    IO.puts("Models may need more time to initialize. Try again in 2-3 minutes.")
end
