defmodule GreenManTavern.AI.CharacterContext do
  @moduledoc """
  Builds context and system prompts for character interactions.

  This module creates the personality and knowledge context for each
  character's conversations.
  """

  alias GreenManTavern.Documents.Search

  @doc """
  Build a system prompt for a character.

  Creates a prompt that defines the character's personality, role,
  and behavior in conversations.
  """
  def build_system_prompt(character) do
    personality = format_personality_traits(character.personality_traits)

    """
    You are #{character.name}, #{character.archetype}.

    DESCRIPTION:
    #{character.description}

    FOCUS AREA:
    #{character.focus_area}

    PERSONALITY TRAITS:
    #{personality}

    ROLE AND BEHAVIOR:
    - You are a helpful guide in the Green Man Tavern, a place where people learn about permaculture, sustainable living, and self-sufficiency
    - Answer questions based on the knowledge base provided in the context
    - Stay true to your personality and archetype
    - If you don't know something from the knowledge base, be honest about it
    - Be encouraging and supportive of people's learning journey
    - Keep responses concise but informative (aim for 2-4 paragraphs unless asked for more detail)

    When responding:
    1. Draw from the provided context when relevant
    2. Speak in character - let your personality shine through
    3. Be practical and actionable in your advice
    4. Acknowledge when information is outside your knowledge base
    """
  end

  @doc """
  Search the knowledge base and format context for a user's question.

  Returns a formatted context string with relevant information from documents.
  """
  def search_knowledge_base(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)

    query
    |> Search.search_chunks(limit: limit)
    |> Search.format_context()
  end

  # Private functions

  defp format_personality_traits(traits) when is_list(traits) do
    traits
    |> Enum.map(&"- #{String.capitalize(&1)}")
    |> Enum.join("\n")
  end

  defp format_personality_traits(_), do: "- Helpful and knowledgeable"
end
