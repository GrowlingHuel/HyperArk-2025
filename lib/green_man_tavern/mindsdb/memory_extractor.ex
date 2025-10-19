defmodule GreenManTavern.MindsDB.MemoryExtractor do
  @moduledoc """
  Extracts and stores user project mentions from conversations.
  Matches the specification from Phase 3.4 in the architecture file.
  """

  alias GreenManTavern.Repo
  alias GreenManTavern.Projects.UserProject
  import Ecto.Query

  @doc """
  Extract project mentions from user messages and update user_projects table.
  Called after each user message in character chat.
  """
  def extract_and_store_projects(user_id, message_text) do
    projects = extract_projects(message_text)

    Enum.each(projects, fn {project_type, status, confidence} ->
      create_or_update_project(user_id, project_type, status, confidence)
    end)
  end

  @doc """
  Get active projects for a user to include in agent context.
  Called by ContextBuilder when building context for MindsDB queries.
  """
  def get_active_projects(user_id) do
    query =
      from up in UserProject,
      where: up.user_id == ^user_id and up.status != "abandoned",
      order_by: [desc: up.mentioned_at]

    Repo.all(query)
  end

  def extract_projects(message_text) do
    message_text
    |> String.downcase()
    |> extract_project_mentions()
    |> Enum.uniq()
  end

  defp extract_project_mentions(text) do
    projects = []

    # Pattern matching as specified in architecture file
    projects = if String.contains?(text, "want to") or String.contains?(text, "would like to") do
      extract_from_pattern(text, ~r/(?:want to|would like to) (\w+)/, "desire", 0.7) ++ projects
    else
      projects
    end

    projects = if String.contains?(text, "planning to") or String.contains?(text, "going to") do
      extract_from_pattern(text, ~r/(?:planning to|going to) (\w+)/, "planning", 0.8) ++ projects
    else
      projects
    end

    projects = if String.contains?(text, "started") or String.contains?(text, "beginning") do
      extract_from_pattern(text, ~r/(?:started|beginning) (\w+)/, "in_progress", 0.9) ++ projects
    else
      projects
    end

    projects = if String.contains?(text, "have") and (String.contains?(text, "chickens") or
                String.contains?(text, "garden") or String.contains?(text, "compost")) do
      extract_from_pattern(text, ~r/have (?:a )?(\w+)/, "completed", 1.0) ++ projects
    else
      projects
    end

    # Specific project type detection
    projects = if String.contains?(text, "chicken") do
      [{"chickens", infer_status(text), infer_confidence(text)} | projects]
    else
      projects
    end

    projects = if String.contains?(text, "compost") do
      [{"composting", infer_status(text), infer_confidence(text)} | projects]
    else
      projects
    end

    projects = if String.contains?(text, "garden") or String.contains?(text, "plant") do
      [{"garden", infer_status(text), infer_confidence(text)} | projects]
    else
      projects
    end

    projects = if String.contains?(text, "herb") do
      [{"herb_garden", infer_status(text), infer_confidence(text)} | projects]
    else
      projects
    end

    projects
  end

  defp extract_from_pattern(text, pattern, status, confidence) do
    Regex.scan(pattern, text)
    |> Enum.map(fn [_, project] ->
      {normalize_project_type(project), status, confidence}
    end)
  end

  defp infer_status(text) do
    cond do
      String.contains?(text, "want to") -> "desire"
      String.contains?(text, "planning") -> "planning"
      String.contains?(text, "started") -> "in_progress"
      String.contains?(text, "have") -> "completed"
      true -> "desire"
    end
  end

  defp infer_confidence(text) do
    cond do
      String.contains?(text, "want to") -> 0.7
      String.contains?(text, "planning") -> 0.8
      String.contains?(text, "started") -> 0.9
      String.contains?(text, "have") -> 1.0
      true -> 0.6
    end
  end

  defp normalize_project_type(project_type) do
    case String.downcase(project_type) do
      "chicken" -> "chickens"
      "compost" -> "composting"
      "garden" -> "vegetable_garden"
      "herb" -> "herb_garden"
      "plant" -> "garden"
      other -> other
    end
  end

  defp create_or_update_project(user_id, project_type, status, confidence) do
    # Check if project already exists for this user
    existing_project = Repo.get_by(UserProject, user_id: user_id, project_type: project_type)

    changeset_data = %{
      status: status,
      confidence_score: confidence,
      mentioned_at: DateTime.utc_now() |> DateTime.to_naive()
    }

    if existing_project do
      # Update existing project
      UserProject.changeset(existing_project, changeset_data)
      |> Repo.update()
    else
      # Create new project
      %UserProject{}
      |> UserProject.changeset(Map.merge(%{
        user_id: user_id,
        project_type: project_type
      }, changeset_data))
      |> Repo.insert()
    end
  end
end
