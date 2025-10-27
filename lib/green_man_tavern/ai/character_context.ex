defmodule GreenManTavern.AI.CharacterContext do
  @moduledoc """
  Builds context and system prompts for character interactions.

  This module is responsible for creating the personality, knowledge,
  and behavioral context for each character's AI-powered conversations.
  It integrates character data with the knowledge base to provide rich,
  contextually-aware interactions.

  ## Features

  - **System Prompts**: Creates detailed personality definitions for Claude
  - **Knowledge Search**: Searches the PDF knowledge base for relevant context
  - **Context Formatting**: Formats knowledge base results for Claude's use
  """

  alias GreenManTavern.Documents.Search

  @doc """
  Builds a system prompt for a character to guide their AI conversations.

  Creates a comprehensive prompt that defines the character's personality,
  role, focus area, and behavioral guidelines for Claude. This prompt
  ensures consistent character behavior across all interactions.

  ## Parameters

  - `character` - A `%Character{}` struct with personality data

  ## Returns

  A string containing the system prompt for Claude.

  ## Examples

      iex> character = %Character{name: "The Grandmother", archetype: "Elder Wisdom", ...}
      iex> CharacterContext.build_system_prompt(character)
      "You are The Grandmother, Elder Wisdom.\\n\\nDESCRIPTION:\\n..."

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
  Searches the knowledge base and formats context for a user's question.

  This function searches the PDF knowledge base using semantic search,
  retrieves relevant document chunks, and formats them as context for
  Claude. The knowledge base contains permaculture and sustainable
  living information.

  ## Parameters

  - `query` - The user's question or message to search for
  - `opts` - Keyword list of options
    - `:limit` - Maximum number of chunks to return (default: 5)

  ## Returns

  A formatted context string with relevant information from the knowledge base.
  Returns an empty string if no relevant content is found.

  ## Examples

      iex> CharacterContext.search_knowledge_base("How to build a compost bin?")
      "Context from permaculture_guide.pdf:\\n\\nBuilding a compost bin requires..."

      iex> CharacterContext.search_knowledge_base("unknown topic", limit: 10)
      ""

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
