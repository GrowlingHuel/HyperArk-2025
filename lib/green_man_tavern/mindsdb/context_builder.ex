defmodule GreenManTavern.MindsDB.ContextBuilder do
  @moduledoc """
  Builds context for MindsDB agent queries by gathering user information,
  project data, conversation history, and character-specific context.
  """

  alias GreenManTavern.MindsDB.MemoryExtractor
  alias GreenManTavern.Characters
  alias GreenManTavern.Conversations

  @doc """
  Builds comprehensive user context for MindsDB agent queries.

  ## Parameters
  - `user_id` - The ID of the user
  - `character` - The character struct being interacted with

  ## Returns
  A context string containing user information, projects, and conversation history.
  """
  def build_user_context(user_id, character) when is_nil(user_id) do
    build_guest_context(character)
  end

  def build_user_context(user_id, character) do
    # Get user's active projects
    active_projects = MemoryExtractor.get_active_projects(user_id)

    # Get recent conversation history
    recent_conversations = Conversations.get_recent_conversation(user_id, character.id, 5)

    # Get user's trust level with this character
    trust_level = Characters.get_trust_level(user_id, character.id)

    # Build context string
    build_context_string(user_id, character, active_projects, recent_conversations, trust_level)
  end

  defp build_guest_context(character) do
    """
    Character: #{character.name}
    Archetype: #{character.archetype}
    Focus Area: #{character.focus_area}
    Description: #{character.description}

    This is a guest user with no previous interaction history.
    """
  end

  defp build_context_string(user_id, character, active_projects, recent_conversations, trust_level) do
    projects_context = build_projects_context(active_projects)
    conversation_context = build_conversation_context(recent_conversations)
    character_context = build_character_context(character)
    trust_context = build_trust_context(trust_level)

    """
    User ID: #{user_id}

    #{character_context}

    #{trust_context}

    #{projects_context}

    #{conversation_context}
    """
  end

  defp build_projects_context([]) do
    "Active Projects: None"
  end

  defp build_projects_context(projects) do
    project_list =
      projects
      |> Enum.map(fn project ->
        "- #{project.project_type}: #{project.status} (confidence: #{project.confidence_score})"
      end)
      |> Enum.join("\n")

    "Active Projects:\n#{project_list}"
  end

  defp build_conversation_context([]) do
    "Recent Conversation: None"
  end

  defp build_conversation_context(conversations) do
    conversation_list =
      conversations
      |> Enum.take(5)  # Limit to last 5 messages
      |> Enum.map(fn conv ->
        "#{conv.message_type}: #{conv.content}"
      end)
      |> Enum.join("\n")

    "Recent Conversation:\n#{conversation_list}"
  end

  defp build_character_context(character) do
    """
    Character: #{character.name}
    Archetype: #{character.archetype}
    Focus Area: #{character.focus_area}
    Description: #{character.description}
    Trust Requirement: #{character.trust_requirement}
    """
  end

  defp build_trust_context(trust_level) do
    case trust_level do
      0 -> "Trust Level: New relationship (0)"
      level when level < 20 -> "Trust Level: Acquaintance (#{level})"
      level when level < 50 -> "Trust Level: Friend (#{level})"
      level when level < 100 -> "Trust Level: Close Friend (#{level})"
      level -> "Trust Level: Trusted Companion (#{level})"
    end
  end
end
