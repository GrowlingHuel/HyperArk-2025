# start_knowledge_upload.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== STARTING KNOWLEDGE BASE UPLOAD ===")

pdf_path = Path.expand("~/Projects/HyperArk-2025/priv/knowledge/permaculture_PDFs/")

case File.ls(pdf_path) do
  {:ok, files} ->
    pdf_files = Enum.filter(files, &String.ends_with?(&1, ".pdf"))
    IO.puts("Found #{length(pdf_files)} PDF files to upload")
    IO.puts("First 5 files:")

    Enum.each(Enum.take(pdf_files, 5), fn file ->
      IO.puts("  📚 #{file}")
    end)

    # We'll implement the actual upload logic next
    IO.puts("\\n✅ Knowledge base ready for upload!")
    IO.puts("   Once models are working, we'll upload all PDFs")

  {:error, reason} ->
    IO.puts("❌ Cannot access PDF directory: #{inspect(reason)}")
end
