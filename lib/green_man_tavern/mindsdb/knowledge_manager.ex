defmodule GreenManTavern.MindsDB.KnowledgeManager do
  alias GreenManTavern.MindsDB.HTTPClient

  @moduledoc """
  Handles uploading and managing knowledge base documents in MindsDB.

  Coordinates PDF extraction, chunking, and upload to MindsDB's
  knowledge base system. Provides comprehensive management of
  permaculture PDF documents for AI agent training.

  ## Features

  - **PDF Upload**: Upload individual PDF files with metadata
  - **Batch Processing**: Upload entire directories of PDFs
  - **Progress Tracking**: Monitor upload progress with detailed statistics
  - **Duplicate Handling**: Skip existing files or force re-upload
  - **Concurrent Processing**: Parallel uploads for better performance
  - **Metadata Management**: Categorize and tag documents
  - **File Management**: List, check existence, and get statistics

  ## Usage

      # Upload a single PDF
      {:ok, result} = KnowledgeManager.upload_pdf("guide.pdf", category: "composting")

      # Upload all PDFs in a directory
      {:ok, summary} = KnowledgeManager.upload_directory("priv/mindsdb/knowledge/")

      # Check upload statistics
      stats = KnowledgeManager.get_upload_stats()

      # List uploaded files
      {:ok, files} = KnowledgeManager.list_uploaded_files()
  """

  require Logger
  alias GreenManTavern.Knowledge.PDFExtractor
  alias GreenManTavern.MindsDB.HTTPClient

  # Default configuration
  @default_chunk_size 1000
  @default_max_concurrent 3
  @default_category "general"
  @upload_timeout 300_000

  # Public API

  @doc """
  Uploads a single PDF file to MindsDB knowledge base.

  Extracts text, chunks it, and uploads to MindsDB with metadata.
  Handles file validation, extraction errors, and upload failures.

  ## Parameters

  - `file_path` - Path to the PDF file (string)
  - `opts` - Upload options (keyword list)

  ## Options

  - `:category` - Document category (string, default: "general")
  - `:tags` - List of tags for the document (list of strings, default: [])
  - `:chunk_size` - Words per chunk (integer, default: 1000)
  - `:force` - Force re-upload even if file exists (boolean, default: false)

  ## Returns

  - `{:ok, upload_result}` - Successfully uploaded with result details
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> KnowledgeManager.upload_pdf("composting_guide.pdf", category: "composting", tags: ["soil", "organic"])
      {:ok, %{"file_id" => "123", "name" => "composting_guide.pdf", "chunks" => 15}}

      iex> KnowledgeManager.upload_pdf("nonexistent.pdf")
      {:error, :file_not_found}
  """
  @spec upload_pdf(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def upload_pdf(file_path, opts \\ []) when is_binary(file_path) do
    category = Keyword.get(opts, :category, @default_category)
    tags = Keyword.get(opts, :tags, [])
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    force = Keyword.get(opts, :force, false)

    Logger.info("Starting PDF upload",
      file_path: file_path,
      category: category,
      chunk_size: chunk_size
    )

    with :ok <- validate_upload_file(file_path, force),
         {:ok, extraction_result} <- PDFExtractor.extract_with_chunks(file_path, chunk_size),
         {:ok, upload_result} <- upload_to_mindsdb(extraction_result, file_path, category, tags) do
      Logger.info("Successfully uploaded PDF",
        file_path: file_path,
        chunks: extraction_result.chunk_count,
        words: extraction_result.total_words
      )

      {:ok, upload_result}
    else
      error ->
        Logger.error("Failed to upload PDF",
          file_path: file_path,
          error: error
        )

        {:error, error}
    end
  end

  @doc """
  Uploads all PDFs in a directory to MindsDB.

  Processes multiple PDF files concurrently with progress tracking.
  Supports recursive directory scanning and duplicate handling.

  ## Parameters

  - `dir_path` - Path to directory containing PDFs (string)
  - `opts` - Upload options (keyword list)

  ## Options

  - `:recursive` - Process subdirectories (boolean, default: false)
  - `:skip_existing` - Skip files already uploaded (boolean, default: true)
  - `:category` - Default category for all files (string, default: "general")
  - `:max_concurrent` - Maximum parallel uploads (integer, default: 3)
  - `:chunk_size` - Words per chunk (integer, default: 1000)
  - `:force` - Force re-upload existing files (boolean, default: false)

  ## Returns

  - `{:ok, summary}` - Upload summary with statistics
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> KnowledgeManager.upload_directory("priv/mindsdb/knowledge/", recursive: true, max_concurrent: 5)
      {:ok, %{uploaded: 25, skipped: 8, failed: 2, total: 35}}

      iex> KnowledgeManager.upload_directory("nonexistent/")
      {:ok, %{uploaded: 0, skipped: 0, failed: 0, total: 0}}
  """
  @spec upload_directory(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def upload_directory(dir_path, opts \\ []) when is_binary(dir_path) do
    recursive = Keyword.get(opts, :recursive, false)
    skip_existing = Keyword.get(opts, :skip_existing, true)
    category = Keyword.get(opts, :category, @default_category)
    max_concurrent = Keyword.get(opts, :max_concurrent, @default_max_concurrent)
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    force = Keyword.get(opts, :force, false)

    Logger.info("Starting directory upload",
      dir_path: dir_path,
      recursive: recursive,
      max_concurrent: max_concurrent
    )

    with :ok <- validate_directory(dir_path),
         pdf_files <- find_pdf_files(dir_path, recursive) do
      if Enum.empty?(pdf_files) do
        Logger.warning("No PDF files found", dir_path: dir_path)
        {:ok, create_empty_summary()}
      else
        Logger.info("Found PDF files", count: length(pdf_files))

        # Upload files with progress tracking
        upload_results =
          pdf_files
          |> Task.async_stream(
            &upload_single_file(&1, category, skip_existing, chunk_size, force),
            max_concurrency: max_concurrent,
            timeout: @upload_timeout
          )
          |> Enum.map(fn
            {:ok, result} -> result
            {:exit, reason} -> {:failed, "unknown", reason}
          end)

        # Summarize results
        summary = summarize_upload_results(upload_results, pdf_files)

        Logger.info("Directory upload complete",
          uploaded: summary.uploaded,
          skipped: summary.skipped,
          failed: summary.failed,
          total: summary.total
        )

        {:ok, summary}
      end
    else
      error ->
        Logger.error("Failed to upload directory",
          dir_path: dir_path,
          error: error
        )

        {:error, error}
    end
  end

  @doc """
  Lists all uploaded files in MindsDB knowledge base.

  Returns detailed information about each uploaded file including
  metadata, chunk counts, and upload timestamps.

  ## Returns

  - `{:ok, files}` - List of file information maps
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> KnowledgeManager.list_uploaded_files()
      {:ok, [%{"name" => "guide.pdf", "chunks" => 15, "size" => 5000}]}
  """
  @spec list_uploaded_files() :: {:ok, [map()]} | {:error, term()}
  def list_uploaded_files do
    Logger.debug("Listing uploaded files")

    case HTTPClient.list_files() do
      {:ok, files} ->
        Logger.debug("Retrieved files", count: length(files))
        {:ok, files}

      {:error, reason} ->
        Logger.error("Failed to list files", error: reason)
        {:error, reason}
    end
  end

  @doc """
  Checks if a file already exists in MindsDB knowledge base.

  Compares by filename and handles various naming patterns.

  ## Parameters

  - `filename` - Name of the file to check (string)

  ## Returns

  - `boolean()` - True if file exists, false otherwise

  ## Examples

      iex> KnowledgeManager.file_exists?("composting_guide.pdf")
      true

      iex> KnowledgeManager.file_exists?("nonexistent.pdf")
      false
  """
  @spec file_exists?(String.t()) :: boolean()
  def file_exists?(filename) when is_binary(filename) do
    case list_uploaded_files() do
      {:ok, files} ->
        files
        |> Enum.any?(fn file ->
          file_name = file["name"] || ""

          file_name == filename ||
            String.ends_with?(file_name, filename) ||
            String.ends_with?(filename, file_name)
        end)

      _ ->
        Logger.warning("Could not check file existence", filename: filename)
        false
    end
  end

  @doc """
  Gets comprehensive upload statistics for the knowledge base.

  Provides detailed metrics about uploaded files including
  total counts, sizes, categories, and file types.

  ## Returns

  - `map()` - Statistics map with various metrics

  ## Examples

      iex> KnowledgeManager.get_upload_stats()
      %{
        total_files: 35,
        total_size: 150000,
        categories: %{"composting" => 5, "seed_saving" => 8},
        file_types: %{".pdf" => 35}
      }
  """
  @spec get_upload_stats() :: map()
  def get_upload_stats do
    Logger.debug("Getting upload statistics")

    case list_uploaded_files() do
      {:ok, files} ->
        stats = %{
          total_files: length(files),
          total_size: calculate_total_size(files),
          categories: count_categories(files),
          file_types: count_file_types(files),
          chunk_totals: calculate_chunk_totals(files),
          upload_dates: extract_upload_dates(files)
        }

        Logger.debug("Calculated statistics", stats: stats)
        stats

      _ ->
        Logger.warning("Could not calculate statistics")
        create_empty_stats()
    end
  end

  @doc """
  Removes a file from the MindsDB knowledge base.

  Permanently deletes the file and all associated chunks.

  ## Parameters

  - `filename` - Name of the file to remove (string)

  ## Returns

  - `{:ok, :removed}` - Successfully removed
  - `{:error, reason}` - Error with reason

  ## Examples

      iex> KnowledgeManager.remove_file("old_guide.pdf")
      {:ok, :removed}

      iex> KnowledgeManager.remove_file("nonexistent.pdf")
      {:error, :file_not_found}
  """
  @spec remove_file(String.t()) :: {:ok, :removed} | {:error, term()}
  def remove_file(filename) when is_binary(filename) do
    Logger.info("Removing file from knowledge base", filename: filename)

    if file_exists?(filename) do
      case HTTPClient.delete_file(filename) do
        {:ok, _} ->
          Logger.info("Successfully removed file", filename: filename)
          {:ok, :removed}

        {:error, reason} ->
          Logger.error("Failed to remove file", filename: filename, error: reason)
          {:error, reason}
      end
    else
      Logger.warning("File not found for removal", filename: filename)
      {:error, :file_not_found}
    end
  end

  # Private Functions

  defp validate_upload_file(file_path, force) do
    cond do
      not File.exists?(file_path) ->
        {:error, :file_not_found}

      not String.ends_with?(String.downcase(file_path), ".pdf") ->
        {:error, :not_a_pdf_file}

      File.stat!(file_path).size == 0 ->
        {:error, :empty_file}

      not force and file_exists?(Path.basename(file_path)) ->
        {:error, :file_already_exists}

      true ->
        :ok
    end
  end

  defp validate_directory(dir_path) do
    cond do
      not File.exists?(dir_path) ->
        {:error, :directory_not_found}

      not File.dir?(dir_path) ->
        {:error, :not_a_directory}

      true ->
        :ok
    end
  end

  defp find_pdf_files(dir_path, recursive) do
    pattern = if recursive, do: "**/*.pdf", else: "*.pdf"

    Path.wildcard(Path.join(dir_path, pattern))
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
  end

  defp upload_to_mindsdb(extraction_result, file_path, category, tags) do
    # Prepare comprehensive file metadata
    metadata = %{
      title: Path.basename(file_path, ".pdf"),
      filename: Path.basename(file_path),
      category: category,
      tags: tags,
      chunks: extraction_result.chunk_count,
      total_words: extraction_result.total_words,
      chunk_size: extraction_result.chunk_size,
      extracted_at: DateTime.utc_now(),
      file_size: File.stat!(file_path).size,
      source_path: file_path
    }

    Logger.debug("Preparing upload to MindsDB",
      file: Path.basename(file_path),
      chunks: extraction_result.chunk_count,
      words: extraction_result.total_words
    )

    # Upload to MindsDB via HTTP client
    case HTTPClient.upload_file(file_path, metadata) do
      {:ok, response} ->
        upload_result = %{
          "file_id" => response["file_id"] || "upload_#{System.unique_integer([:positive])}",
          "name" => Path.basename(file_path),
          "size" => extraction_result.total_words,
          "chunks" => extraction_result.chunk_count,
          "metadata" => metadata,
          "uploaded_at" => DateTime.utc_now()
        }

        {:ok, upload_result}

      {:error, reason} ->
        Logger.error("MindsDB upload failed", error: reason)
        {:error, {:upload_failed, reason}}
    end
  end

  defp upload_single_file(file_path, category, skip_existing, chunk_size, force) do
    filename = Path.basename(file_path)

    if skip_existing and not force and file_exists?(filename) do
      Logger.info("Skipping existing file", filename: filename)
      {:skipped, filename}
    else
      case upload_pdf(file_path,
             category: category,
             chunk_size: chunk_size,
             force: force
           ) do
        {:ok, result} ->
          {:uploaded, filename, result}

        {:error, reason} ->
          Logger.error("Upload failed", filename: filename, error: reason)
          {:failed, filename, reason}
      end
    end
  end

  defp summarize_upload_results(results, all_files) do
    uploaded = Enum.count(results, &match?({:uploaded, _, _}, &1))
    skipped = Enum.count(results, &match?({:skipped, _}, &1))
    failed = Enum.count(results, &match?({:failed, _, _}, &1))

    failed_files =
      results
      |> Enum.filter(&match?({:failed, _, _}, &1))
      |> Enum.map(fn {:failed, filename, reason} -> {filename, reason} end)

    %{
      uploaded: uploaded,
      skipped: skipped,
      failed: failed,
      total: length(all_files),
      success_rate:
        if(length(all_files) > 0, do: Float.round(uploaded / length(all_files) * 100, 2), else: 0),
      failed_files: failed_files,
      results: results
    }
  end

  defp calculate_total_size(files) do
    files
    |> Enum.reduce(0, fn file, acc ->
      size = file["size"] || file["metadata"]["file_size"] || 0
      acc + size
    end)
  end

  defp count_categories(files) do
    files
    |> Enum.map(fn file ->
      file["metadata"]["category"] ||
        file["category"] ||
        "unknown"
    end)
    |> Enum.frequencies()
  end

  defp count_file_types(files) do
    files
    |> Enum.map(fn file ->
      Path.extname(file["name"] || "")
    end)
    |> Enum.frequencies()
  end

  defp calculate_chunk_totals(files) do
    files
    |> Enum.reduce(0, fn file, acc ->
      chunks = file["chunks"] || file["metadata"]["chunks"] || 0
      acc + chunks
    end)
  end

  defp extract_upload_dates(files) do
    files
    |> Enum.map(fn file ->
      file["uploaded_at"] ||
        file["metadata"]["extracted_at"] ||
        "unknown"
    end)
    |> Enum.frequencies()
  end

  defp create_empty_summary do
    %{
      uploaded: 0,
      skipped: 0,
      failed: 0,
      total: 0,
      success_rate: 0,
      failed_files: [],
      results: []
    }
  end

  defp create_empty_stats do
    %{
      total_files: 0,
      total_size: 0,
      categories: %{},
      file_types: %{},
      chunk_totals: 0,
      upload_dates: %{}
    }
  end
end
