defmodule GreenManTavern.Documents do
  @moduledoc """
  The Documents context for managing PDF knowledge base.

  This context provides functions for managing documents and their chunks
  in the Green Man Tavern knowledge base system. It handles PDF processing,
  text chunking, and metadata management for AI agent training.

  ## Features

  - **Document Management**: Create, read, update, delete documents
  - **Chunk Management**: Create and manage text chunks from documents
  - **Metadata Handling**: Store and retrieve document metadata
  - **Search and Filtering**: Query documents by various criteria
  - **Bulk Operations**: Process multiple documents efficiently

  ## Usage

      # Create a new document
      {:ok, document} = Documents.create_document(%{
        title: "Composting Guide",
        source_file: "composting.pdf",
        file_path: "/uploads/composting.pdf",
        metadata: %{category: "composting", author: "John Doe"}
      })

      # Add chunks to the document
      {:ok, chunk} = Documents.create_chunk(document.id, %{
        content: "Composting is the process of...",
        chunk_index: 0,
        metadata: %{page_number: 1, section_heading: "Introduction"}
      })

      # List documents by category
      documents = Documents.list_documents_by_category("composting")
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  require Logger

  alias GreenManTavern.Documents.{Document, DocumentChunk}

  # Document functions

  @doc """
  Returns the list of documents.

  ## Examples

      iex> list_documents()
      [%Document{}, ...]

  """
  def list_documents do
    Repo.all(Document)
  end

  @doc """
  Returns the list of documents with their chunks preloaded.

  ## Examples

      iex> list_documents_with_chunks()
      [%Document{chunks: [%DocumentChunk{}, ...]}, ...]

  """
  def list_documents_with_chunks do
    Document
    |> preload(:chunks)
    |> Repo.all()
  end

  @doc """
  Lists documents by category.

  ## Examples

      iex> list_documents_by_category("composting")
      [%Document{metadata: %{category: "composting"}}, ...]

  """
  def list_documents_by_category(category) do
    Document
    |> where([d], fragment("?->>'category' = ?", d.metadata, ^category))
    |> Repo.all()
  end

  @doc """
  Lists processed documents (those with processed_at timestamp).

  ## Examples

      iex> list_processed_documents()
      [%Document{processed_at: ~U[2024-01-15 10:30:00Z]}, ...]

  """
  def list_processed_documents do
    Document
    |> where([d], not is_nil(d.processed_at))
    |> Repo.all()
  end

  @doc """
  Gets a single document.

  Raises if the Document does not exist.

  ## Examples

      iex> get_document!(123)
      %Document{}

  """
  def get_document!(id) do
    Repo.get!(Document, id)
  end

  @doc """
  Gets a single document with chunks preloaded.

  Raises if the Document does not exist.

  ## Examples

      iex> get_document_with_chunks!(123)
      %Document{chunks: [%DocumentChunk{}, ...]}

  """
  def get_document_with_chunks!(id) do
    Document
    |> preload(:chunks)
    |> Repo.get!(id)
  end

  @doc """
  Creates a document.

  ## Examples

      iex> create_document(%{title: "Guide", source_file: "guide.pdf", file_path: "/path/to/guide.pdf"})
      {:ok, %Document{}}

      iex> create_document(%{title: "Guide"})
      {:error, %Ecto.Changeset{}}

  """
  def create_document(attrs \\ %{}) do
    %Document{}
    |> Document.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document.

  ## Examples

      iex> update_document(document, %{title: new_title})
      {:ok, %Document{}}

      iex> update_document(document, %{title: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the total chunks count for a document.

  ## Examples

      iex> update_document_chunks_count(document, 15)
      {:ok, %Document{total_chunks: 15}}

  """
  def update_document_chunks_count(%Document{} = document, count) do
    document
    |> Document.update_chunks_count_changeset(count)
    |> Repo.update()
  end

  @doc """
  Marks a document as processed.

  ## Examples

      iex> mark_document_processed(document)
      {:ok, %Document{processed_at: ~U[2024-01-15 10:30:00Z]}}

  """
  def mark_document_processed(%Document{} = document) do
    document
    |> Document.mark_processed_changeset()
    |> Repo.update()
  end

  @doc """
  Updates document metadata.

  ## Examples

      iex> update_document_metadata(document, %{category: "soil_health", author: "Jane Doe"})
      {:ok, %Document{metadata: %{category: "soil_health", author: "Jane Doe"}}}

  """
  def update_document_metadata(%Document{} = document, metadata) do
    document
    |> Document.update_metadata_changeset(metadata)
    |> Repo.update()
  end

  @doc """
  Deletes a document.

  This will also delete all associated chunks due to the foreign key constraint.

  ## Examples

      iex> delete_document(document)
      {:ok, %Document{}}

      iex> delete_document(document)
      {:error, %Ecto.Changeset{}}

  """
  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end

  @doc """
  Returns a data structure for tracking document changes.

  ## Examples

      iex> change_document(document)
      %Ecto.Changeset{data: %Document{}}

  """
  def change_document(%Document{} = document, attrs \\ %{}) do
    Document.changeset(document, attrs)
  end

  # DocumentChunk functions

  @doc """
  Returns the list of chunks for a document.

  ## Examples

      iex> list_chunks_for_document(document_id)
      [%DocumentChunk{}, ...]

  """
  def list_chunks_for_document(document_id) do
    DocumentChunk
    |> where([c], c.document_id == ^document_id)
    |> order_by([c], asc: c.chunk_index)
    |> Repo.all()
  end

  @doc """
  Gets a single chunk.

  Raises if the DocumentChunk does not exist.

  ## Examples

      iex> get_chunk!(123)
      %DocumentChunk{}

  """
  def get_chunk!(id) do
    Repo.get!(DocumentChunk, id)
  end

  @doc """
  Creates a chunk for a document.

  ## Examples

      iex> create_chunk(document_id, %{content: "Text content", chunk_index: 0})
      {:ok, %DocumentChunk{}}

      iex> create_chunk(document_id, %{content: "Text"})
      {:error, %Ecto.Changeset{}}

  """
  def create_chunk(document_id, attrs \\ %{}) do
    attrs = Map.put(attrs, :document_id, document_id)

    %DocumentChunk{}
    |> DocumentChunk.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates multiple chunks for a document in a single transaction.

  ## Examples

      iex> create_chunks(document_id, [%{content: "Chunk 1", chunk_index: 0}, %{content: "Chunk 2", chunk_index: 1}])
      {:ok, [%DocumentChunk{}, %DocumentChunk{}]}

  """
  def create_chunks(document_id, chunks_attrs) do
    Repo.transaction(fn ->
      chunks_attrs
      |> Enum.with_index()
      |> Enum.map(fn {attrs, index} ->
        attrs = Map.put(attrs, :chunk_index, index)
        {:ok, chunk} = create_chunk(document_id, attrs)
        chunk
      end)
    end)
  end

  @doc """
  Updates a chunk.

  ## Examples

      iex> update_chunk(chunk, %{content: new_content})
      {:ok, %DocumentChunk{}}

      iex> update_chunk(chunk, %{content: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chunk(%DocumentChunk{} = chunk, attrs) do
    chunk
    |> DocumentChunk.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates chunk metadata.

  ## Examples

      iex> update_chunk_metadata(chunk, %{page_number: 5, section_heading: "Methods"})
      {:ok, %DocumentChunk{metadata: %{page_number: 5, section_heading: "Methods"}}}

  """
  def update_chunk_metadata(%DocumentChunk{} = chunk, metadata) do
    chunk
    |> DocumentChunk.update_metadata_changeset(metadata)
    |> Repo.update()
  end

  @doc """
  Deletes a chunk.

  ## Examples

      iex> delete_chunk(chunk)
      {:ok, %DocumentChunk{}}

      iex> delete_chunk(chunk)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chunk(%DocumentChunk{} = chunk) do
    Repo.delete(chunk)
  end

  @doc """
  Returns a data structure for tracking chunk changes.

  ## Examples

      iex> change_chunk(chunk)
      %Ecto.Changeset{data: %DocumentChunk{}}

  """
  def change_chunk(%DocumentChunk{} = chunk, attrs \\ %{}) do
    DocumentChunk.changeset(chunk, attrs)
  end

  # Utility functions

  @doc """
  Gets document statistics.

  ## Examples

      iex> get_document_stats()
      %{total_documents: 25, total_chunks: 1250, processed_documents: 20}

  """
  def get_document_stats do
    total_documents = Repo.aggregate(Document, :count, :id)
    total_chunks = Repo.aggregate(DocumentChunk, :count, :id)

    processed_documents =
      Document
      |> where([d], not is_nil(d.processed_at))
      |> Repo.aggregate(:count, :id)

    %{
      total_documents: total_documents,
      total_chunks: total_chunks,
      processed_documents: processed_documents,
      unprocessed_documents: total_documents - processed_documents
    }
  end

  @doc """
  Gets documents by metadata field.

  ## Examples

      iex> get_documents_by_metadata_field("category", "composting")
      [%Document{metadata: %{category: "composting"}}, ...]

  """
  def get_documents_by_metadata_field(field, value) do
    Document
    |> where([d], fragment("?->>? = ?", d.metadata, ^field, ^value))
    |> Repo.all()
  end

  # Batch processing functions

  @doc """
  Processes all PDFs in a directory and stores them with chunks in the database.

  Options:
  - `:chunk_size` - Size of text chunks (default: 1000)
  - `:overlap` - Overlap between chunks (default: 200)
  - `:skip_existing` - Skip already processed files (default: true)
  - `:batch_insert_size` - Number of chunks to insert at once (default: 100)

  Returns summary map with processing statistics.
  """
  @spec process_pdf_directory(Path.t(), keyword()) ::
    {:ok, map()} | {:error, term()}
  def process_pdf_directory(directory_path, opts \\ []) do

    chunk_size = Keyword.get(opts, :chunk_size, 1000)
    overlap = Keyword.get(opts, :overlap, 200)
    skip_existing = Keyword.get(opts, :skip_existing, true)
    batch_size = Keyword.get(opts, :batch_insert_size, 100)

    start_time = System.monotonic_time(:second)

    Logger.info("Starting PDF directory processing: #{directory_path}")

    with {:ok, pdf_files} <- find_pdf_files(directory_path),
         {:ok, results} <- process_files(pdf_files, chunk_size, overlap, skip_existing, batch_size) do

      duration = System.monotonic_time(:second) - start_time
      summary = build_summary(results, duration)
      Logger.info("Processing complete: #{summary.processed} processed, #{summary.failed} failed")
      {:ok, summary}
    end
  end

  @doc """
  Check if a document with this source file already exists and is processed.
  """
  @spec document_exists?(String.t()) :: boolean()
  def document_exists?(source_file) do
    from(d in Document,
      where: d.source_file == ^source_file and not is_nil(d.processed_at)
    )
    |> Repo.exists?()
  end

  @doc """
  Get document by source filename.
  """
  @spec get_document_by_source(String.t()) :: Document.t() | nil
  def get_document_by_source(source_file) do
    from(d in Document, where: d.source_file == ^source_file)
    |> Repo.one()
  end

  # Private helper functions for batch processing

  defp find_pdf_files(directory_path) do
    case File.dir?(directory_path) do
      true ->
        pdf_files =
          directory_path
          |> Path.join("**/*.pdf")
          |> Path.wildcard()
          |> Enum.sort()

        if Enum.empty?(pdf_files) do
          {:error, :no_pdf_files}
        else
          {:ok, pdf_files}
        end

      false ->
        {:error, :directory_not_found}
    end
  end

  defp process_files(pdf_files, chunk_size, overlap, skip_existing, _batch_size) do
    Logger.info("Found #{length(pdf_files)} PDF files to process")

    results =
      pdf_files
      |> Enum.with_index(1)
      |> Enum.reduce([], fn {file_path, index}, acc ->
        # Log progress every 5 files
        if rem(index, 5) == 0 do
          Logger.info("Processing file #{index}/#{length(pdf_files)}: #{Path.basename(file_path)}")
        end

        case process_single_pdf(file_path, chunk_size, overlap, skip_existing) do
          {:ok, stats} ->
            Logger.debug("Successfully processed: #{Path.basename(file_path)} (#{stats.chunk_count} chunks)")
            [{:ok, stats} | acc]

          {:error, reason} ->
            Logger.error("Failed to process #{Path.basename(file_path)}: #{inspect(reason)}")
            [{:error, %{file: Path.basename(file_path), reason: reason}} | acc]
        end
      end)
      |> Enum.reverse()

    {:ok, results}
  end

  defp process_single_pdf(file_path, chunk_size, overlap, skip_existing) do
    filename = Path.basename(file_path)
    Logger.debug("Processing PDF: #{filename}")

    # Check if already processed
    if skip_existing and document_exists?(filename) do
      Logger.debug("Skipping already processed file: #{filename}")
      {:ok, %{file: filename, chunk_count: 0, status: :skipped}}
    else
      with {:ok, text_data} <- extract_pdf_text(file_path),
           {:ok, chunks} <- chunk_pdf_text(text_data, chunk_size, overlap),
           {:ok, document} <- store_document_with_chunks(file_path, text_data, chunks) do

        {:ok, %{
          file: filename,
          chunk_count: length(chunks),
          status: :processed,
          document_id: document.id
        }}
      end
    end
  end

  defp extract_pdf_text(file_path) do
    alias GreenManTavern.Documents.PDFProcessor

    case PDFProcessor.extract_with_metadata(file_path) do
      {:ok, result} ->
        # Result already has the structure we need: %{text: ..., metadata: ..., page_count: ...}
        # Add file_size to the result
        {:ok, Map.put(result, :file_size, File.stat!(file_path).size)}

      {:error, reason} = error ->
        Logger.error("PDF extraction failed for #{Path.basename(file_path)}: #{inspect(reason)}")
        error
    end
  end

  defp chunk_pdf_text(text_data, chunk_size, overlap) do
    alias GreenManTavern.Documents.TextChunker

    doc_metadata = %{
      page_count: text_data.page_count,
      file_size: text_data.file_size
    }

    # Merge any additional metadata from PDFProcessor
    doc_metadata = Map.merge(doc_metadata, text_data.metadata || %{})

    case TextChunker.chunk_with_metadata(text_data.text, doc_metadata,
           chunk_size: chunk_size, overlap: overlap) do
      {:ok, chunks} -> {:ok, chunks}
      {:error, reason} -> {:error, reason}
    end
  end

  defp store_document_with_chunks(file_path, text_data, chunks) do
    filename = Path.basename(file_path)
    title = filename |> Path.rootname() |> String.replace("_", " ") |> String.capitalize()

    # Prepare document attributes
    doc_attrs = %{
      title: title,
      source_file: filename,
      file_path: file_path,
      total_chunks: length(chunks),
      metadata: %{
        page_count: text_data.page_count,
        file_size: text_data.file_size,
        processed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }
    }

    # Merge any additional metadata from PDFProcessor
    doc_attrs = put_in(doc_attrs.metadata, Map.merge(doc_attrs.metadata, text_data.metadata || %{}))

    # Use Ecto.Multi for transactional insert
    multi = Ecto.Multi.new()

    # 1. Create Document record
    multi = Ecto.Multi.insert(multi, :document, Document.create_changeset(%Document{}, doc_attrs))

# 2. Create all DocumentChunk records (batch insert)
    # We need to add document_id after the document is created
    multi = Ecto.Multi.run(multi, :chunks, fn _repo, %{document: document} ->
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      
      chunk_attrs =
        chunks
        |> Enum.map(fn chunk ->
          %{
            document_id: document.id,
            content: chunk.content,
            chunk_index: chunk.index,
            character_count: chunk.metadata.character_count,
            metadata: chunk.metadata,
            inserted_at: now,
            updated_at: now
          }
        end)

      {count, _} = Repo.insert_all(DocumentChunk, chunk_attrs)
      {:ok, {count, nil}}
    end)

    # Execute transaction
    case Repo.transaction(multi) do
      {:ok, %{document: document, chunks: {count, _chunks}}} ->
        # Update document with actual chunk count
        document
        |> Document.update_chunks_count_changeset(count)
        |> Repo.update()

        {:ok, document}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp build_summary(results, duration) do
    total_files = length(results)

    {successes, failures} =
      results
      |> Enum.split_with(fn
        {:ok, _} -> true
        {:error, _} -> false
      end)

    processed =
      successes
      |> Enum.count(fn {:ok, stats} -> stats.status == :processed end)

    skipped =
      successes
      |> Enum.count(fn {:ok, stats} -> stats.status == :skipped end)

    failed = length(failures)

    total_chunks =
      successes
      |> Enum.reduce(0, fn {:ok, stats}, acc -> acc + stats.chunk_count end)

    errors =
      failures
      |> Enum.map(fn {:error, error} -> error end)

    %{
      total_files: total_files,
      processed: processed,
      skipped: skipped,
      failed: failed,
      total_chunks: total_chunks,
      errors: errors,
      duration_seconds: duration
    }
  end
end
