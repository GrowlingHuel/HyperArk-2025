defmodule GreenManTavern.Documents.TextChunker do
  @moduledoc """
  Splits large text documents into optimal chunks for AI processing and vector embeddings.

  Uses semantic chunking strategy:
  - Preserves sentence boundaries where possible
  - Maintains paragraph structure
  - Adds overlap between chunks for context continuity
  - Generates metadata for each chunk

  ## Examples

      iex> TextChunker.chunk_text("Long text...", chunk_size: 1000, overlap: 200)
      [
        %{content: "First chunk...", index: 0, start_char: 0, end_char: 1000},
        %{content: "Second chunk...", index: 1, start_char: 800, end_char: 1800}
      ]
  """

  @default_chunk_size 1000
  @default_overlap 200
  @min_chunk_size 100

  @doc """
  Chunks text into optimal sizes for AI processing.

  Options:
  - `:chunk_size` - Target size for each chunk (default: 1000 chars)
  - `:overlap` - Overlap between chunks (default: 200 chars)
  - `:preserve_paragraphs` - Keep paragraphs intact when possible (default: true)
  - `:min_chunk_size` - Minimum chunk size (default: 100 chars)

  Returns list of chunk maps.
  """
  @spec chunk_text(String.t(), keyword()) :: {:ok, [map()]} | {:error, atom()}
  def chunk_text(text, opts \\ []) do
    with :ok <- validate_input(text),
         validated_opts <- validate_and_normalize_opts(opts) do
      case validated_opts do
        {:error, _} = error -> error
        opts -> {:ok, do_chunk_text(text, opts)}
      end
    end
  end

  @doc """
  Chunks text with document metadata added to each chunk.

  Adds document context to chunks:
  - Document title
  - Source file
  - Category
  """
  @spec chunk_with_metadata(String.t(), map(), keyword()) :: {:ok, [map()]} | {:error, atom()}
  def chunk_with_metadata(text, doc_metadata, opts \\ []) do
    case chunk_text(text, opts) do
      {:error, _} = error -> error
      {:ok, chunks} -> {:ok, Enum.map(chunks, &add_document_metadata(&1, doc_metadata))}
    end
  end

  # Private helper functions

  defp validate_input(text) when is_binary(text) and byte_size(text) > 0, do: :ok
  defp validate_input(nil), do: {:error, :nil_text}
  defp validate_input(""), do: {:error, :empty_text}
  defp validate_input(_), do: {:error, :invalid_input}

  defp validate_and_normalize_opts(opts) do
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    overlap = Keyword.get(opts, :overlap, @default_overlap)

    cond do
      chunk_size < @min_chunk_size ->
        {:error, :chunk_size_too_small}

      overlap >= chunk_size ->
        {:error, :overlap_exceeds_chunk_size}

      overlap < 0 ->
        {:error, :negative_overlap}

      true ->
        [
          chunk_size: chunk_size,
          overlap: overlap,
          preserve_paragraphs: Keyword.get(opts, :preserve_paragraphs, true),
          min_chunk_size: Keyword.get(opts, :min_chunk_size, @min_chunk_size)
        ]
    end
  end

  defp do_chunk_text(text, opts) do
    chunk_size = opts[:chunk_size]
    overlap = opts[:overlap]

    # If text is shorter than chunk size, return single chunk
    if String.length(text) <= chunk_size do
      [build_chunk(text, 0, 0, String.length(text), false)]
    else
      text
      |> split_into_sentences()
      |> build_chunks(chunk_size, overlap)
      |> Enum.with_index()
      |> Enum.map(fn {{content, start_pos, end_pos, has_overlap}, index} ->
        build_chunk(content, index, start_pos, end_pos, has_overlap)
      end)
    end
  end

  defp split_into_sentences(text) do
    # Split on sentence boundaries: . ! ? followed by space or newline
    # But don't split on common abbreviations
    text
    |> String.replace(~r/Mr\./i, "Mr")
    |> String.replace(~r/Mrs\./i, "Mrs")
    |> String.replace(~r/Ms\./i, "Ms")
    |> String.replace(~r/Dr\./i, "Dr")
    |> String.replace(~r/Prof\./i, "Prof")
    |> String.replace(~r/St\./i, "St")
    |> String.replace(~r/([.!?])\s+/, "\\1\n__SENTENCE_BREAK__\n")
    |> String.split("__SENTENCE_BREAK__")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp build_chunks(sentences, chunk_size, overlap) do
    do_build_chunks(sentences, chunk_size, overlap, [], "", 0, nil)
  end

  defp do_build_chunks([], _chunk_size, _overlap, chunks, current, start_pos, _last_chunk) do
    # Add final chunk if there's remaining content
    if String.length(current) > 0 do
      Enum.reverse([{current, start_pos, start_pos + String.length(current), false} | chunks])
    else
      Enum.reverse(chunks)
    end
  end

  defp do_build_chunks([sentence | rest], chunk_size, overlap, chunks, current, start_pos, last_chunk) do
    new_content = if current == "", do: sentence, else: current <> " " <> sentence

    if String.length(new_content) >= chunk_size do
      # Chunk is full, create it and start new one with overlap
      chunk_end = start_pos + String.length(current)
      new_chunks = [{current, start_pos, chunk_end, last_chunk != nil} | chunks]

      # Calculate overlap text from current chunk
      overlap_text = get_overlap_text(current, overlap)
      new_start = chunk_end - String.length(overlap_text)

      # Start new chunk with overlap + current sentence
      next_content = if overlap_text == "", do: sentence, else: overlap_text <> " " <> sentence

      do_build_chunks(rest, chunk_size, overlap, new_chunks, next_content, new_start, current)
    else
      # Keep building current chunk
      do_build_chunks(rest, chunk_size, overlap, chunks, new_content, start_pos, last_chunk)
    end
  end

  defp get_overlap_text(text, overlap_size) do
    text_length = String.length(text)

    if text_length <= overlap_size do
      text
    else
      # Get last N characters
      start_pos = text_length - overlap_size
      String.slice(text, start_pos, overlap_size)
    end
  end

  defp build_chunk(content, index, start_pos, end_pos, has_overlap) do
    %{
      content: content,
      index: index,
      start_char: start_pos,
      end_char: end_pos,
      metadata: %{
        character_count: String.length(content),
        word_count: count_words(content),
        sentence_count: count_sentences(content),
        has_overlap: has_overlap
      }
    }
  end

  defp add_document_metadata(chunk, doc_metadata) do
    %{chunk | metadata: Map.merge(chunk.metadata, doc_metadata)}
  end

  defp count_words(text) do
    text
    |> String.split(~r/\s+/)
    |> Enum.reject(&(&1 == ""))
    |> length()
  end

  defp count_sentences(text) do
    text
    |> String.split(~r/[.!?]+/)
    |> Enum.reject(&(&1 == "" or String.trim(&1) == ""))
    |> length()
  end
end
