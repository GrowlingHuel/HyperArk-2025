# upload_knowledge_base.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== STARTING KNOWLEDGE BASE UPLOAD ===")

pdf_path = Path.expand("~/Projects/HyperArk-2025/priv/knowledge/permaculture_PDFs/")

case File.ls(pdf_path) do
  {:ok, files} ->
    pdf_files = Enum.filter(files, &String.ends_with?(&1, ".pdf"))
    IO.puts("Found #{length(pdf_files)} PDF files to upload")
    
    # Upload first 3 files to start
    Enum.each(Enum.take(pdf_files, 3), fn file ->
      file_path = Path.join(pdf_path, file)
      IO.puts("\\n📤 Uploading: #{file}")
      
      # Use our existing knowledge manager to upload
      case GreenManTavern.MindsDB.KnowledgeManager.upload_pdf(file_path) do
        {:ok, result} ->
          IO.puts("   ✅ Uploaded successfully!")
          IO.puts("   Result: #{inspect(result)}")
        {:error, reason} ->
          IO.puts("   ❌ Upload failed: #{inspect(reason)}")
      end
    end)
    
    IO.puts("\\n✅ Knowledge base upload initiated!")
    IO.puts("   Remaining files: #{length(pdf_files) - 3}")
    
  {:error, reason} ->
    IO.puts("❌ Cannot access PDF directory: #{inspect(reason)}")
end
