defmodule Mix.Tasks.Documents.ProcessPdfs do
  @moduledoc """
  Mix task to process all PDFs in a directory and store them in the database.

  This task provides a command-line interface for the batch PDF processing
  pipeline, allowing you to process all 45 permaculture PDFs efficiently.

  ## Usage

      # Process all PDFs in a directory with default options
      mix documents.process_pdfs /path/to/pdf/directory

      # Process with custom chunk size and overlap
      mix documents.process_pdfs /path/to/pdf/directory --chunk-size 1500 --overlap 300

      # Process without skipping existing files
      mix documents.process_pdfs /path/to/pdf/directory --no-skip-existing

      # Process with verbose logging
      mix documents.process_pdfs /path/to/pdf/directory --verbose

  ## Options

  - `--chunk-size` - Size of text chunks (default: 1000)
  - `--overlap` - Overlap between chunks (default: 200)
  - `--no-skip-existing` - Process all files, even if already processed
  - `--batch-size` - Number of chunks to insert at once (default: 100)
  - `--verbose` - Enable verbose logging

  ## Examples

      # Process PDFs with larger chunks for better context
      mix documents.process_pdfs ./pdfs --chunk-size 2000 --overlap 400

      # Reprocess all PDFs (useful for testing)
      mix documents.process_pdfs ./pdfs --no-skip-existing

      # Process with detailed logging
      mix documents.process_pdfs ./pdfs --verbose
  """

  use Mix.Task

  @shortdoc "Process all PDFs in a directory and store them in the database"

  @switches [
    chunk_size: :integer,
    overlap: :integer,
    skip_existing: :boolean,
    batch_size: :integer,
    verbose: :boolean
  ]

  @aliases [
    c: :chunk_size,
    o: :overlap,
    b: :batch_size,
    v: :verbose
  ]

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    case args do
      [directory_path] ->
        process_directory(directory_path, opts)

      [] ->
        Mix.shell().error("Error: Directory path is required")
        Mix.shell().info("Usage: mix documents.process_pdfs <directory_path> [options]")
        Mix.shell().info("Run 'mix help documents.process_pdfs' for more information.")
        System.halt(1)

      _ ->
        Mix.shell().error("Error: Too many arguments")
        Mix.shell().info("Usage: mix documents.process_pdfs <directory_path> [options]")
        System.halt(1)
    end
  end

  defp process_directory(directory_path, opts) do
    # Start the application
    Mix.Task.run("app.start")

    # Configure logging level
    if opts[:verbose] do
      Logger.configure(level: :debug)
    else
      Logger.configure(level: :info)
    end

    # Display banner
    display_banner()

    # Normalize options
    processing_opts = normalize_opts(opts)

    # Display configuration
    display_configuration(directory_path, processing_opts)

    # Process the directory
    case GreenManTavern.Documents.process_pdf_directory(directory_path, processing_opts) do
      {:ok, summary} ->
        display_success_summary(summary)

      {:error, reason} ->
        display_error(reason)
        System.halt(1)
    end
  end

  defp display_banner do
    Mix.shell().info("""
    ╔══════════════════════════════════════════════════════════════╗
    ║                    PDF Batch Processing                     ║
    ║                Green Man Tavern Knowledge Base               ║
    ╚══════════════════════════════════════════════════════════════╝
    """)
  end

  defp normalize_opts(opts) do
    [
      chunk_size: opts[:chunk_size] || 1000,
      overlap: opts[:overlap] || 200,
      # Default to true
      skip_existing: opts[:skip_existing] != false,
      batch_insert_size: opts[:batch_size] || 100
    ]
  end

  defp display_configuration(directory_path, opts) do
    Mix.shell().info("""
    📁 Directory: #{directory_path}
    📄 Chunk Size: #{opts[:chunk_size]} characters
    🔄 Overlap: #{opts[:overlap]} characters
    ⏭️  Skip Existing: #{opts[:skip_existing]}
    📦 Batch Size: #{opts[:batch_insert_size]} chunks
    """)
  end

  defp display_success_summary(summary) do
    Mix.shell().info("""
    ✅ Processing Complete!

    📊 Summary:
    ├─ Total Files: #{summary.total_files}
    ├─ Processed: #{summary.processed}
    ├─ Skipped: #{summary.skipped}
    ├─ Failed: #{summary.failed}
    ├─ Total Chunks: #{summary.total_chunks}
    └─ Duration: #{summary.duration_seconds} seconds

    """)

    if summary.failed > 0 do
      Mix.shell().error("❌ Failed Files:")

      Enum.each(summary.errors, fn error ->
        Mix.shell().error("   • #{error.file}: #{error.reason}")
      end)

      Mix.shell().info("")
    end

    if summary.processed > 0 do
      Mix.shell().info("🎉 Successfully processed #{summary.processed} PDF files!")
      Mix.shell().info("📚 Created #{summary.total_chunks} text chunks for AI processing.")
    end

    Mix.shell().info("""
    Next Steps:
    • PDFs are ready for AI processing
    • Test character conversations with the processed content
    """)
  end

  defp display_error(reason) do
    Mix.shell().error("❌ Processing failed: #{inspect(reason)}")

    case reason do
      :directory_not_found ->
        Mix.shell().error("The specified directory does not exist.")

      :no_pdf_files ->
        Mix.shell().error("No PDF files found in the specified directory.")

      _ ->
        Mix.shell().error("An unexpected error occurred during processing.")
    end
  end
end
