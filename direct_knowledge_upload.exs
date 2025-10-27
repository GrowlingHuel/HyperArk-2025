# direct_knowledge_upload.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== DIRECT KNOWLEDGE UPLOAD ===")

pdf_path = Path.expand("~/Projects/HyperArk-2025/priv/knowledge/permaculture_PDFs/")

case File.ls(pdf_path) do
  {:ok, files} ->
    pdf_files = Enum.filter(files, &String.ends_with?(&1, ".pdf"))
    IO.puts("Found #{length(pdf_files)} PDF files")

    # Upload just one file first to test
    test_file = Enum.at(pdf_files, 0)
    file_path = Path.join(pdf_path, test_file)

    IO.puts("\\n🧪 Testing upload with: #{test_file}")

    # Extract text and metadata first
    case GreenManTavern.Knowledge.PDFExtractor.extract_text(file_path) do
      {:ok, text} ->
        IO.puts("✅ Text extraction successful (#{String.length(text)} chars)")

        case GreenManTavern.Knowledge.PDFExtractor.extract_metadata(file_path) do
          {:ok, metadata} ->
            IO.puts("✅ Metadata extraction successful")
            IO.puts("   Title: #{Map.get(metadata, :title, "Unknown")}")
            IO.puts("   Pages: #{Map.get(metadata, :pages, "Unknown")}")

            # Try direct HTTP upload
            IO.puts("\\n📤 Attempting direct upload...")

            case GreenManTavern.MindsDB.HTTPClient.upload_file(file_path, metadata) do
              {:ok, upload_result} ->
                IO.puts("🎉 DIRECT UPLOAD SUCCESS!")
                IO.puts("   Result: #{inspect(upload_result)}")

                # If successful, upload a few more
                IO.puts("\\n📚 Uploading additional files...")

                Enum.each(Enum.take(pdf_files, 3), fn file ->
                  additional_path = Path.join(pdf_path, file)
                  IO.puts("   Processing: #{file}")

                  case GreenManTavern.Knowledge.PDFExtractor.extract_text(additional_path) do
                    {:ok, _} ->
                      case GreenManTavern.MindsDB.HTTPClient.upload_file(additional_path, %{}) do
                        {:ok, _} -> IO.puts("     ✅ Uploaded")
                        {:error, reason} -> IO.puts("     ❌ Upload failed: #{inspect(reason)}")
                      end

                    {:error, reason} ->
                      IO.puts("     ❌ Extraction failed: #{inspect(reason)}")
                  end
                end)

              {:error, reason} ->
                IO.puts("❌ Direct upload failed: #{inspect(reason)}")
                IO.puts("   This might be a MindsDB version compatibility issue")
            end

          {:error, metadata_reason} ->
            IO.puts("❌ Metadata extraction failed: #{inspect(metadata_reason)}")
        end

      {:error, text_reason} ->
        IO.puts("❌ Text extraction failed: #{inspect(text_reason)}")
    end

  {:error, reason} ->
    IO.puts("❌ Cannot access PDF directory: #{inspect(reason)}")
end
