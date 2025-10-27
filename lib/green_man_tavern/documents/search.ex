defmodule GreenManTavern.Documents.Search do
  @moduledoc """
  Search functionality for finding relevant document chunks.

  This module provides semantic search capabilities across the document
  knowledge base to support RAG (Retrieval-Augmented Generation) for
  character conversations.
  """

  import Ecto.Query
  alias GreenManTavern.Repo
  alias GreenManTavern.Documents.DocumentChunk

  @doc """
  Search for relevant document chunks based on a query string.

  Uses basic keyword matching. For better results, this should be
  enhanced with embeddings and vector similarity search.

  ## Parameters
  - query: The search query string
  - opts: Options for the search
    - :limit - Maximum number of chunks to return (default: 5)
    - :min_length - Minimum content length to consider (default: 100)

  ## Returns
  A list of maps containing:
  - content: The chunk content
  - document_title: The source document title
  - chunk_index: Position in document
  - relevance_score: Simple relevance score (0-1)
  """
  def search_chunks(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    min_length = Keyword.get(opts, :min_length, 100)

    # Extract keywords from query
    keywords = extract_keywords(query)

    if Enum.empty?(keywords) do
      []
    else
      # Build search query
      search_query = build_search_query(keywords, limit, min_length)

      # Execute and score results
      Repo.all(search_query)
      |> Enum.map(&add_relevance_score(&1, keywords))
      |> Enum.sort_by(& &1.relevance_score, :desc)
    end
  end

  @doc """
  Get context string from search results suitable for LLM prompts.

  Formats the search results into a readable context block.
  """
  def format_context(search_results) do
    if Enum.empty?(search_results) do
      "No relevant information found in the knowledge base."
    else
      search_results
      |> Enum.with_index(1)
      |> Enum.map_join("\n\n", fn {result, idx} ->
        """
        [Source #{idx}: #{result.document_title}]
        #{String.trim(result.content)}
        """
      end)
    end
  end

  # Private functions

  defp extract_keywords(query) do
    # Simple keyword extraction - split on whitespace and remove common words
    stop_words = ~w(the a an and or but in on at to for of with by from)

    query
    |> String.downcase()
    |> String.replace(~r/[^\w\s]/, " ")
    |> String.split()
    |> Enum.reject(&(&1 in stop_words))
    |> Enum.reject(&(String.length(&1) < 3))
    |> Enum.uniq()
  end

  defp build_search_query(keywords, limit, min_length) do
    # Build ILIKE conditions for each keyword
    keyword_conditions =
      Enum.reduce(keywords, dynamic(true), fn keyword, dynamic_query ->
        dynamic([c], ^dynamic_query and ilike(c.content, ^"%#{keyword}%"))
      end)

    from(c in DocumentChunk,
      join: d in assoc(c, :document),
      where: ^keyword_conditions,
      where: c.character_count >= ^min_length,
      select: %{
        id: c.id,
        content: c.content,
        document_title: d.title,
        chunk_index: c.chunk_index,
        character_count: c.character_count,
        metadata: c.metadata
      },
      limit: ^limit
    )
  end

  defp add_relevance_score(result, keywords) do
    content_lower = String.downcase(result.content)

    # Count keyword occurrences
    total_matches =
      Enum.reduce(keywords, 0, fn keyword, acc ->
        matches = content_lower |> String.split(keyword) |> length() |> Kernel.-(1)
        acc + matches
      end)

    # Simple relevance score based on keyword density
    score = min(total_matches / 10.0, 1.0)

    Map.put(result, :relevance_score, score)
  end
end
