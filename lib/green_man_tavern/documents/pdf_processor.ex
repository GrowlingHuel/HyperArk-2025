defmodule GreenManTavern.Documents.PDFProcessor do
  @moduledoc """
  Extracts text content from PDF files for the knowledge base.

  Supports multiple extraction methods with automatic fallback:
  1. Primary: Elixir :pdf library
  2. Fallback: System pdftotext command at /usr/bin/pdftotext

  ## Features

  - **Dual Extraction Methods**: Library-based and system command fallback
  - **Robust Error Handling**: Handles corrupted, encrypted, and scanned PDFs
  - **File Validation**: Size limits, format checking, and security validation
  - **Text Sanitization**: Clean extraction with normalized formatting
  - **Timeout Protection**: Prevents hanging on problematic PDFs
  - **Metadata Extraction**: Page count, file size, and extraction method tracking

  ## Configuration

  PDF processing settings can be configured in `config/config.exs`:

      config :green_man_tavern, :pdf_processing,
        temp_dir: System.tmp_dir(),
        max_file_size_mb: 50,
        timeout_seconds: 120,
        pdftotext_path: "/usr/bin/pdftotext"

  ## Examples

      iex> PDFProcessor.extract_text("/path/to/file.pdf")
      {:ok, "Full text content..."}

      iex> PDFProcessor.extract_with_metadata("/path/to/file.pdf")
      {:ok, %{text: "content...", page_count: 42, metadata: %{...}}}

      iex> PDFProcessor.extract_text("/path/to/corrupted.pdf")
      {:error, :corrupted_file}
  """

  require Logger

  @config Application.compile_env(:green_man_tavern, :pdf_processing, [])
  @max_file_size_mb Keyword.get(@config, :max_file_size_mb, 50)
  @timeout_ms Keyword.get(@config, :timeout_seconds, 120) * 1000
  @pdftotext_path Keyword.get(@config, :pdftotext_path, "/usr/bin/pdftotext")
  @temp_dir Keyword.get(@config, :temp_dir, System.tmp_dir())

  @doc """
  Extracts text from a PDF file.

  Returns {:ok, text} or {:error, reason}

  ## Examples

      iex> PDFProcessor.extract_text("/path/to/file.pdf")
      {:ok, "Full text content..."}

      iex> PDFProcessor.extract_text("/path/to/corrupted.pdf")
      {:error, :corrupted_file}
  """
  @spec extract_text(Path.t()) :: {:ok, String.t()} | {:error, atom()}
  def extract_text(pdf_path) do
    case extract_with_metadata(pdf_path) do
      {:ok, %{text: text}} -> {:ok, text}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Extracts text with metadata (page count, extraction method, etc.)

  Returns {:ok, %{text: string, page_count: integer, metadata: map}}
  or {:error, reason}

  ## Examples

      iex> PDFProcessor.extract_with_metadata("/path/to/file.pdf")
      {:ok, %{
        text: "content...",
        page_count: 42,
        metadata: %{
          extraction_method: :library,
          original_size_bytes: 1024000,
          text_length: 50000
        }
      }}
  """
  @spec extract_with_metadata(Path.t()) ::
          {:ok, %{text: String.t(), page_count: integer(), metadata: map()}}
          | {:error, atom()}
  def extract_with_metadata(pdf_path) do
    Logger.info("Starting PDF extraction", file: Path.basename(pdf_path))

    with :ok <- validate_file(pdf_path),
         {:ok, result} <- try_extraction(pdf_path) do
      sanitized_text = sanitize_text(result.text)

      Logger.info("PDF extraction successful",
        file: Path.basename(pdf_path),
        pages: result.page_count,
        method: result.method,
        text_length: String.length(sanitized_text)
      )

      {:ok,
       %{
         text: sanitized_text,
         page_count: result.page_count,
         metadata: %{
           extraction_method: result.method,
           original_size_bytes: File.stat!(pdf_path).size,
           text_length: String.length(sanitized_text),
           extracted_at: DateTime.utc_now() |> DateTime.truncate(:second)
         }
       }}
    else
      {:error, reason} = error ->
        Logger.error("PDF extraction failed",
          file: Path.basename(pdf_path),
          reason: reason
        )

        error
    end
  end

  # Private functions

  defp validate_file(pdf_path) do
    cond do
      not File.exists?(pdf_path) ->
        {:error, :file_not_found}

      not String.ends_with?(String.downcase(pdf_path), ".pdf") ->
        {:error, :not_a_pdf}

      File.stat!(pdf_path).size > @max_file_size_mb * 1024 * 1024 ->
        {:error, :file_too_large}

      File.stat!(pdf_path).size == 0 ->
        {:error, :empty_file}

      true ->
        :ok
    end
  end

  defp try_extraction(pdf_path) do
    # Try library first, fallback to pdftotext
    case extract_with_library(pdf_path) do
      {:ok, _} = result ->
        result

      {:error, _} ->
        Logger.warning("Library extraction failed, trying pdftotext fallback",
          file: Path.basename(pdf_path)
        )

        extract_with_pdftotext(pdf_path)
    end
  end

  defp extract_with_library(pdf_path) do
    try do
      Logger.debug("Attempting library-based extraction", file: Path.basename(pdf_path))

      # Read PDF file
      pdf_binary = File.read!(pdf_path)

      # Parse PDF using :pdf library
      case :pdf.parse(pdf_binary) do
        {:ok, pdf_doc} ->
          # Extract text from all pages
          text_parts = extract_text_from_pages(pdf_doc)
          combined_text = Enum.join(text_parts, "\n\n")

          # Count pages
          page_count = length(text_parts)

          if String.trim(combined_text) == "" do
            {:error, :no_text_content}
          else
            {:ok,
             %{
               text: combined_text,
               page_count: page_count,
               method: :library
             }}
          end

        {:error, reason} ->
          Logger.debug("PDF library parsing failed",
            file: Path.basename(pdf_path),
            reason: reason
          )

          {:error, :parsing_failed}
      end
    rescue
      error ->
        Logger.debug("PDF library extraction error",
          file: Path.basename(pdf_path),
          error: inspect(error)
        )

        {:error, :library_error}
    end
  end

  defp extract_text_from_pages(pdf_doc) do
    try do
      # Get page count
      {:ok, page_count} = :pdf.get_page_count(pdf_doc)

      # Extract text from each page
      Enum.map(1..page_count, fn page_num ->
        case :pdf.get_page_text(pdf_doc, page_num) do
          {:ok, text} -> text
          {:error, _} -> ""
        end
      end)
    rescue
      _ ->
        # Fallback: try to extract text without knowing page count
        try do
          case :pdf.get_page_text(pdf_doc, 1) do
            {:ok, text} -> [text]
            {:error, _} -> []
          end
        rescue
          _ -> []
        end
    end
  end

  defp extract_with_pdftotext(pdf_path) do
    # Check if pdftotext is available
    unless File.exists?(@pdftotext_path) do
      Logger.error("pdftotext not found at configured path", path: @pdftotext_path)
      {:error, :pdftotext_not_found}
    else
      # Create temporary output file
      case Briefly.create(extname: ".txt") do
        {:ok, temp_file} ->
          try do
            Logger.debug("Attempting pdftotext extraction",
              file: Path.basename(pdf_path),
              temp_file: temp_file
            )

            # Run pdftotext with timeout
            task =
              Task.async(fn ->
                System.cmd(@pdftotext_path, ["-layout", pdf_path, temp_file],
                  stderr_to_stdout: true
                )
              end)

            case Task.await(task, @timeout_ms) do
              {_output, 0} ->
                # Success - read the extracted text
                case File.read(temp_file) do
                  {:ok, _text} ->
                    # Convert binary/iodata to proper string
                    text = temp_file |> File.read!() |> to_string()

                    if String.trim(text) == "" do
                      {:error, :no_text_content}
                    else
                      # Count pages using pdftotext info
                      page_count = count_pages_with_pdftotext(pdf_path)

                      {:ok,
                       %{
                         text: text,
                         page_count: page_count,
                         method: :pdftotext
                       }}
                    end

                  {:error, reason} ->
                    Logger.error("Failed to read extracted text",
                      file: Path.basename(pdf_path),
                      reason: reason
                    )

                    {:error, :read_error}
                end

              {output, exit_code} ->
                Logger.error("pdftotext command failed",
                  file: Path.basename(pdf_path),
                  exit_code: exit_code,
                  output: output
                )

                # Determine error type based on output
                cond do
                  String.contains?(output, "password") ->
                    {:error, :password_protected}

                  String.contains?(output, "corrupt") or String.contains?(output, "damaged") ->
                    {:error, :corrupted_file}

                  String.contains?(output, "permission") ->
                    {:error, :permission_denied}

                  true ->
                    {:error, :extraction_failed}
                end
            end
          rescue
            Task.TimeoutError ->
              Logger.error("pdftotext extraction timed out",
                file: Path.basename(pdf_path),
                timeout_ms: @timeout_ms
              )

              {:error, :timeout}
          after
            # Clean up temporary file
            File.rm(temp_file)
          end

        {:error, reason} ->
          Logger.error("Failed to create temporary file",
            file: Path.basename(pdf_path),
            reason: reason
          )

          {:error, :temp_file_error}
      end
    end
  end

  defp count_pages_with_pdftotext(pdf_path) do
    try do
      # Use pdftotext with -nopgbrk to get page count
      {output, 0} =
        System.cmd(@pdftotext_path, ["-nopgbrk", pdf_path, "-"], stderr_to_stdout: true)

      # Count page breaks in output
      String.split(output, "\f") |> length()
    rescue
      _ ->
        # Fallback: try to estimate from file size
        file_size = File.stat!(pdf_path).size
        # Rough estimate: 50KB per page
        max(1, div(file_size, 50_000))
    end
  end

  defp sanitize_text(text) when is_binary(text) do
    text
    # Ensure proper string
    |> to_string()
    # Normalize line endings
    |> String.replace(~r/\r\n/, "\n")
    # Normalize CR
    |> String.replace(~r/\r/, "\n")
    # Max 2 consecutive newlines
    |> String.replace(~r/\n{3,}/, "\n\n")
    # Collapse spaces/tabs
    |> String.replace(~r/[ \t]+/, " ")
    # Remove control chars
    |> String.replace(~r/[\x00-\x1F\x7F]/, "")
    |> String.trim()
  end

  # Handle non-string input
  defp sanitize_text(_text), do: ""
end
