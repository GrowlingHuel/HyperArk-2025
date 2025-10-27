defmodule GreenManTavern.Knowledge.PDFExtractor do
  @moduledoc """
  Extracts text content from PDF files for knowledge base ingestion.

  Handles various PDF formats and provides clean text output suitable
  for the knowledge base. Supports text extraction, metadata
  retrieval, and intelligent text chunking for optimal processing.

  ## Features

  - **Text Extraction**: Clean text extraction from PDF files
  - **Metadata Retrieval**: Extract document metadata (title, author, etc.)
  - **Intelligent Chunking**: Split large documents into manageable chunks
  - **Error Handling**: Comprehensive error handling for various PDF issues
  - **Text Cleaning**: Remove excess whitespace and fix encoding issues

  ## Usage

      # Extract text from a PDF file
      {:ok, text} = PDFExtractor.extract_text("path/to/document.pdf")

      # Extract with metadata
      {:ok, metadata} = PDFExtractor.extract_metadata("path/to/document.pdf")

      # Extract text and split into chunks
      {:ok, result} = PDFExtractor.extract_with_chunks("path/to/document.pdf", 1000)

      # Chunk existing text
      chunks = PDFExtractor.chunk_text(text, 1000)
  """

  require Logger
  alias PDFExtractor, as: PDF

  # Default chunk size in words
  @default_chunk_size 1000
  @max_chunk_size 2000
  @min_chunk_size 100

  # Public API

  @doc """
  Extracts text content from a PDF file.

  Returns the full text content of the PDF as a single string.
  Text is cleaned and normalized for optimal processing.

  ## Parameters

  - `file_path` - Path to the PDF file (string)

  ## Returns

  - `{:ok, text}` - Successfully extracted text
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> PDFExtractor.extract_text("priv/pdfs/permaculture_guide.pdf")
      {:ok, "Introduction to Permaculture\\n\\nPermaculture is a design system..."}

      iex> PDFExtractor.extract_text("nonexistent.pdf")
      {:error, :file_not_found}
  """
  @spec extract_text(String.t()) :: {:ok, String.t()} | {:error, term()}
  def extract_text(file_path) when is_binary(file_path) do
    Logger.info("Extracting text from PDF", file_path: file_path)

    with :ok <- validate_file(file_path),
         {:ok, raw_text} <- perform_extraction(file_path) do
      cleaned_text = clean_text(raw_text)

      Logger.info("Successfully extracted text",
        file_path: file_path,
        text_length: String.length(cleaned_text)
      )

      {:ok, cleaned_text}
    else
      error ->
        Logger.error("Failed to extract text from PDF",
          file_path: file_path,
          error: error
        )

        {:error, error}
    end
  end

  @doc """
  Extracts metadata from a PDF file.

  Returns document metadata including title, author, subject, creator,
  and creation/modification dates.

  ## Parameters

  - `file_path` - Path to the PDF file (string)

  ## Returns

  - `{:ok, metadata}` - Successfully extracted metadata map
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> PDFExtractor.extract_metadata("priv/pdfs/guide.pdf")
      {:ok, %{title: "Permaculture Guide", author: "John Doe", pages: 45}}

      iex> PDFExtractor.extract_metadata("corrupted.pdf")
      {:error, :corrupted_file}
  """
  @spec extract_metadata(String.t()) :: {:ok, map()} | {:error, term()}
  def extract_metadata(file_path) when is_binary(file_path) do
    Logger.info("Extracting metadata from PDF", file_path: file_path)

    with :ok <- validate_file(file_path),
         {:ok, metadata} <- perform_metadata_extraction(file_path) do
      Logger.info("Successfully extracted metadata",
        file_path: file_path,
        metadata: metadata
      )

      {:ok, metadata}
    else
      error ->
        Logger.error("Failed to extract metadata from PDF",
          file_path: file_path,
          error: error
        )

        {:error, error}
    end
  end

  @doc """
  Splits text into chunks of specified size.

  Intelligently splits text at sentence boundaries to maintain
  readability and context. Chunks are sized by word count.

  ## Parameters

  - `text` - Text to chunk (string)
  - `chunk_size` - Target words per chunk (integer, default: 1000)

  ## Returns

  - `[String.t()]` - List of text chunks

  ## Examples

      iex> PDFExtractor.chunk_text("This is a long text...", 5)
      ["This is a long text.", "More text here.", "And more text."]

      iex> PDFExtractor.chunk_text("Short text", 1000)
      ["Short text"]
  """
  @spec chunk_text(String.t(), integer()) :: [String.t()]
  def chunk_text(text, chunk_size \\ @default_chunk_size)
      when is_binary(text) and is_integer(chunk_size) do
    # Validate chunk size
    validated_size =
      chunk_size
      |> max(@min_chunk_size)
      |> min(@max_chunk_size)

    Logger.debug("Chunking text",
      text_length: String.length(text),
      chunk_size: validated_size
    )

    text
    |> split_into_sentences()
    |> group_sentences_into_chunks(validated_size)
    |> Enum.map(&Enum.join(&1, " "))
    |> Enum.filter(fn chunk -> String.trim(chunk) != "" end)
  end

  @doc """
  Extracts text from PDF and splits it into chunks.

  Combines text extraction and chunking into a single operation.
  Returns structured data with full text, chunks, and metadata.

  ## Parameters

  - `file_path` - Path to the PDF file (string)
  - `chunk_size` - Target words per chunk (integer, default: 1000)

  ## Returns

  - `{:ok, result}` - Successfully extracted and chunked data
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> PDFExtractor.extract_with_chunks("guide.pdf", 500)
      {:ok, %{
        text: "Full text content...",
        chunks: ["Chunk 1...", "Chunk 2..."],
        metadata: %{title: "Guide", pages: 10},
        chunk_count: 2
      }}

      iex> PDFExtractor.extract_with_chunks("corrupted.pdf")
      {:error, :corrupted_file}
  """
  @spec extract_with_chunks(String.t(), integer()) :: {:ok, map()} | {:error, term()}
  def extract_with_chunks(file_path, chunk_size \\ @default_chunk_size)
      when is_binary(file_path) and is_integer(chunk_size) do
    Logger.info("Extracting and chunking PDF",
      file_path: file_path,
      chunk_size: chunk_size
    )

    with {:ok, text} <- extract_text(file_path),
         {:ok, metadata} <- extract_metadata(file_path) do
      chunks = chunk_text(text, chunk_size)

      result = %{
        text: text,
        chunks: chunks,
        metadata: metadata,
        chunk_count: length(chunks),
        chunk_size: chunk_size,
        total_words: count_words(text)
      }

      Logger.info("Successfully extracted and chunked PDF",
        file_path: file_path,
        chunk_count: result.chunk_count,
        total_words: result.total_words
      )

      {:ok, result}
    else
      error -> {:error, error}
    end
  end

  # Private Functions

  defp validate_file(file_path) do
    cond do
      not File.exists?(file_path) ->
        {:error, :file_not_found}

      not String.ends_with?(String.downcase(file_path), ".pdf") ->
        {:error, :not_a_pdf_file}

      File.stat!(file_path).size == 0 ->
        {:error, :empty_file}

      true ->
        :ok
    end
  end

  defp perform_extraction(file_path) do
    try do
      case PDF.extract_text(file_path) do
        {:ok, text} when is_binary(text) ->
          {:ok, text}

        {:ok, text} when is_list(text) ->
          # Handle case where PDFExtractor returns a list of strings
          {:ok, Enum.join(text, "\n")}

        {:error, reason} ->
          {:error, reason}

        other ->
          Logger.warning("Unexpected PDFExtractor response", response: other)
          {:error, :unexpected_response}
      end
    rescue
      error ->
        Logger.error("PDF extraction error", error: error)
        {:error, :extraction_failed}
    end
  end

  defp perform_metadata_extraction(file_path) do
    try do
      case PDF.extract_metadata(file_path) do
        {:ok, metadata} when is_map(metadata) ->
          # Normalize metadata keys and add file info
          normalized_metadata =
            metadata
            |> normalize_metadata_keys()
            |> Map.put(:file_path, file_path)
            |> Map.put(:file_size, File.stat!(file_path).size)
            |> Map.put(:extracted_at, DateTime.utc_now())

          {:ok, normalized_metadata}

        {:error, reason} ->
          {:error, reason}

        other ->
          Logger.warning("Unexpected PDFExtractor metadata response", response: other)
          {:error, :unexpected_response}
      end
    rescue
      error ->
        Logger.error("PDF metadata extraction error", error: error)
        {:error, :metadata_extraction_failed}
    end
  end

  defp normalize_metadata_keys(metadata) do
    metadata
    |> Enum.map(fn
      {key, value} when is_atom(key) -> {key, value}
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      other -> other
    end)
    |> Enum.into(%{})
  end

  defp clean_text(text) do
    text
    # Replace multiple whitespace with single space
    |> String.replace(~r/\s+/, " ")
    # Normalize paragraph breaks
    |> String.replace(~r/\n\s*\n/, "\n\n")
    |> String.trim()
  end

  defp split_into_sentences(text) do
    text
    |> String.split(~r/[.!?]+\s+/)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn sentence -> String.length(sentence) > 0 end)
  end

  defp group_sentences_into_chunks(sentences, target_word_count) do
    sentences
    |> Enum.reduce([], fn sentence, acc ->
      case acc do
        [] ->
          [[sentence]]

        [current_chunk | rest] ->
          current_word_count = count_words(Enum.join(current_chunk, " "))

          if current_word_count + count_words(sentence) <= target_word_count do
            [[sentence | current_chunk] | rest]
          else
            [[sentence], current_chunk | rest]
          end
      end
    end)
    |> Enum.reverse()
  end

  defp count_words(text) do
    text
    |> String.split(~r/\s+/)
    |> Enum.filter(fn word -> String.trim(word) != "" end)
    |> length()
  end
end
