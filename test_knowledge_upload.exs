# test_knowledge_upload.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== Testing Knowledge Base Upload ===")

# Check if KnowledgeManager is available
if Code.ensure_loaded?(GreenManTavern.MindsDB.KnowledgeManager) do
  IO.puts("✅ KnowledgeManager available")

  # Test listing PDFs
  pdf_path = Path.expand("~/Projects/HyperArk-2025/priv/knowledge/permaculture_PDFs/")
  IO.puts("PDF directory: #{pdf_path}")

  case File.ls(pdf_path) do
    {:ok, files} ->
      pdf_files = Enum.filter(files, &String.ends_with?(&1, ".pdf"))
      IO.puts("Found #{length(pdf_files)} PDF files:")
      Enum.each(Enum.take(pdf_files, 5), fn file -> IO.puts("  - #{file}") end)
      if length(pdf_files) > 5, do: IO.puts("  ... and #{length(pdf_files) - 5} more")

    {:error, reason} ->
      IO.puts("❌ Cannot list PDF files: #{inspect(reason)}")
  end
else
  IO.puts("❌ KnowledgeManager not available")
end

# Test file operations
IO.puts("\\n=== Testing File Operations ===")

case GreenManTavern.MindsDB.HTTPClient.upload_file("/tmp/test.txt", %{description: "test file"}) do
  {:ok, result} ->
    IO.puts("✅ File upload test successful")
    IO.inspect(result)

  {:error, reason} ->
    IO.puts("❌ File upload test failed: #{inspect(reason)}")
end
