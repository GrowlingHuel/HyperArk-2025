# configure_openrouter.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== Configuring OpenRouter in MindsDB ===")

openrouter_api_key = System.get_env("OPENROUTER_API_KEY")

if is_nil(openrouter_api_key) or openrouter_api_key == "" do
  IO.puts("❌ Please set OPENROUTER_API_KEY environment variable")
  IO.puts("   export OPENROUTER_API_KEY=sk-or-...")
  IO.puts("   Get it from: https://openrouter.ai/keys")
else
  IO.puts("✅ OpenRouter API key found!")

  # Create OpenRouter integration in MindsDB
  create_sql = """
  CREATE ML_ENGINE openai
  FROM openai
  USING
    openai_api_key = '#{openrouter_api_key}',
    openai_api_base = 'https://openrouter.ai/api/v1';
  """

  case GreenManTavern.MindsDB.SQLClient.query(create_sql) do
    {:ok, _} ->
      IO.puts("✅ OpenRouter configured successfully!")

      # Recreate agents with OpenRouter
      IO.puts("Recreating agents with OpenRouter...")

      case GreenManTavern.MindsDB.AgentInstaller.install_all(force: true, verbose: true) do
        :ok ->
          IO.puts("🎉 All agents reconfigured with OpenRouter!")
          IO.puts("Testing one agent...")

          # Give models time to initialize
          :timer.sleep(3000)

          test_query = "SELECT answer FROM student_agent WHERE question = 'What is permaculture?'"

          case GreenManTavern.MindsDB.SQLClient.query(test_query) do
            {:ok, result} ->
              IO.puts("✅ Agent test successful!")
              IO.inspect(result, limit: :infinity)

            {:error, reason} ->
              IO.puts("⚠️ Agent created but query failed (may need more time): #{inspect(reason)}")
          end

        error ->
          IO.puts("❌ Failed to recreate agents: #{inspect(error)}")
      end

    {:error, %{"error_message" => "ML engine 'openai' already exists"} = reason} ->
      IO.puts("ℹ️ OpenAI engine already exists, updating configuration...")

      # Update existing engine
      update_sql = """
      DROP ML_ENGINE openai;
      """

      case GreenManTavern.MindsDB.SQLClient.query(update_sql) do
        {:ok, _} ->
          IO.puts("✅ Dropped old OpenAI engine, recreating with OpenRouter...")
          # Re-run the create
          {:ok, _} = GreenManTavern.MindsDB.SQLClient.query(create_sql)
          IO.puts("✅ OpenRouter configured successfully!")
          GreenManTavern.MindsDB.AgentInstaller.install_all(force: true, verbose: true)

        error ->
          IO.puts("❌ Failed to update engine: #{inspect(error)}")
      end

    {:error, reason} ->
      IO.puts("❌ Failed to configure OpenRouter: #{inspect(reason)}")
  end
end
