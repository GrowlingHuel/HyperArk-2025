defmodule GreenManTavern.MindsDB.AgentInstaller do
  @moduledoc """
  Manages installation and verification of MindsDB agent models.
  """

  alias GreenManTavern.MindsDB.SQLClient

  # Agent Definitions
  @agents %{
    "student_agent" => %{
      name: "student_agent",
      description: "The Student - eager, curious learner of permaculture",
      prompt:
        "You are The Student - an eager, curious learner always excited to explore permaculture. You ask thoughtful questions and love discovering new perspectives. Be enthusiastic, humble, and genuinely interested in learning. When answering questions about: {{question}}, consider the context: {{context}}. User skill level: {{user_skill}}"
    },
    "grandmother_agent" => %{
      name: "grandmother_agent",
      description: "The Grandmother - wise, patient with traditional knowledge",
      prompt:
        "You are The Grandmother - wise, patient, and full of traditional knowledge. You speak with warmth and share wisdom from years of experience. Use gentle metaphors and stories from nature. When answering: {{question}}, remember: {{context}}. User background: {{user_skill}}"
    },
    "farmer_agent" => %{
      name: "farmer_agent",
      description: "The Farmer - practical, no-nonsense, hands-on approach",
      prompt:
        "You are The Farmer - practical, no-nonsense, and hands-on. You focus on what works in the real world. Give straightforward, actionable advice. For question: {{question}}, with context: {{context}}. User experience: {{user_skill}}"
    },
    "robot_agent" => %{
      name: "robot_agent",
      description: "The Robot - analytical, data-driven, and precise",
      prompt:
        "You are The Robot - analytical, precise, and data-driven. You think in systems and patterns. Provide structured, logical responses with clear reasoning. Analyzing: {{question}}. Context data: {{context}}. User proficiency: {{user_skill}}"
    },
    "alchemist_agent" => %{
      name: "alchemist_agent",
      description: "The Alchemist - mystical, sees hidden connections",
      prompt:
        "You are The Alchemist - mystical, intuitive, and seeing hidden connections. You speak in metaphors and reveal the magic in natural processes. For inquiry: {{question}}, considering: {{context}}. User aptitude: {{user_skill}}"
    },
    "survivalist_agent" => %{
      name: "survivalist_agent",
      description: "The Survivalist - resilient, prepared, practical in crisis",
      prompt:
        "You are The Survivalist - resilient, prepared, and practical in crisis. Focus on durability, self-sufficiency, and backup plans. Addressing: {{question}}. Situation: {{context}}. User readiness: {{user_skill}}"
    },
    "hobo_agent" => %{
      name: "hobo_agent",
      description: "The Hobo - wandering sage with unconventional wisdom",
      prompt:
        "You are The Hobo - a wandering sage with unconventional wisdom. You see things from unique angles and share insights from the road. Considering: {{question}}, with perspective: {{context}}. User openness: {{user_skill}}"
    }
  }

  @doc """
  Install all seven character agents.
  """
  def install_all(opts \\ []) do
    verbose = Keyword.get(opts, :verbose, false)
    force = Keyword.get(opts, :force, false)

    IO.puts("🚀 Installing all 7 character agents...")

    results =
      @agents
      |> Enum.map(fn {agent_name, agent_config} ->
        IO.puts("  📝 Installing #{agent_name}...")
        install_agent(agent_name, force: force, verbose: verbose)
      end)

    successful = Enum.filter(results, &(&1 == :ok)) |> length()

    IO.puts(
      "\\n🎉 Installation Complete: #{successful}/#{map_size(@agents)} agents installed successfully"
    )

    if successful == map_size(@agents) do
      :ok
    else
      {:error, "Only #{successful}/#{map_size(@agents)} agents installed"}
    end
  end

  @doc """
  Install a specific agent by name.
  """
  def install_agent(agent_name, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, false)
    force = Keyword.get(opts, :force, false)

    agent_config = @agents[agent_name]

    if is_nil(agent_config) do
      IO.puts("❌ Unknown agent: #{agent_name}")
      {:error, :unknown_agent}
    else
      if !force && agent_exists?(agent_name) do
        if verbose, do: IO.puts("  ⚡ Agent #{agent_name} already exists, skipping")
        :ok
      else
        if agent_exists?(agent_name) do
          IO.puts("  🔄 Re-creating existing agent: #{agent_name}")
          remove_agent(agent_name)
        end

        create_sql = """
        CREATE MODEL #{agent_name}
        PREDICT answer
        USING
          engine = 'openai',
          prompt_template = '#{String.replace(agent_config.prompt, "'", "''")}'
        """

        case SQLClient.query(create_sql) do
          {:ok, _result} ->
            if verbose, do: IO.puts("  ✅ Successfully created #{agent_name}")
            :ok

          {:error, reason} ->
            IO.puts("  ❌ Failed to create #{agent_name}: #{inspect(reason)}")
            {:error, reason}
        end
      end
    end
  end

  @doc """
  List all available agents.
  """
  def list_agents() do
    case SQLClient.list_models() do
      {:ok, %{"data" => data}} ->
        agent_names =
          data
          |> List.flatten()
          |> Enum.filter(fn model_name ->
            is_binary(model_name) && String.ends_with?(model_name, "_agent")
          end)

        {:ok, agent_names}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Check if an agent exists.
  """
  def agent_exists?(agent_name) do
    case list_agents() do
      {:ok, agents} -> agent_name in agents
      _ -> false
    end
  end

  @doc """
  Verify all agents are installed and working.
  """
  def verify_all() do
    IO.puts("🔍 Verifying all agents...")

    results =
      Map.keys(@agents)
      |> Enum.map(fn agent_name ->
        status = verify_agent(agent_name)
        {agent_name, status}
      end)

    successful = Enum.filter(results, &(elem(&1, 1) == :ok)) |> length()

    IO.puts("\\n📊 Verification Results:")

    Enum.each(results, fn {agent_name, status} ->
      status_icon = if status == :ok, do: "✅", else: "❌"
      IO.puts("  #{status_icon} #{agent_name}")
    end)

    if successful == map_size(@agents) do
      IO.puts("\\n🎉 All agents verified successfully!")
      :ok
    else
      {:error, "Only #{successful}/#{map_size(@agents)} agents verified"}
    end
  end

  @doc """
  Verify a specific agent.
  """
  def verify_agent(agent_name) do
    if agent_exists?(agent_name) do
      # Test query to verify the agent responds
      test_query = "SELECT answer FROM #{agent_name} WHERE question = 'Hello, who are you?'"

      case SQLClient.query(test_query) do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end
    else
      :error
    end
  end

  @doc """
  Remove an agent.
  """
  def remove_agent(agent_name) do
    if agent_exists?(agent_name) do
      case SQLClient.drop_model(agent_name) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
  end

  @doc """
  Get agent configuration.
  """
  def get_agent_config(agent_name) do
    @agents[agent_name]
  end

  @doc """
  List all available agent definitions.
  """
  def list_agent_definitions() do
    Map.keys(@agents)
  end
end
