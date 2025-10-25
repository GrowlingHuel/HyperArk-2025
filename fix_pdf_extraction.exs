# fix_pdf_extraction.exs
Application.ensure_all_started(:green_man_tavern)

IO.puts("=== FIXING PDF EXTRACTION ===")

pdf_path = Path.expand("~/Projects/HyperArk-2025/priv/knowledge/permaculture_PDFs/")

case File.ls(pdf_path) do
  {:ok, files} ->
    pdf_files = Enum.filter(files, &String.ends_with?(&1, ".pdf"))
    IO.puts("Found #{length(pdf_files)} PDF files")
    
    # Test with a simple PDF first
    test_file = "homesteadinghandbook.pdf"  # Try a different file
    file_path = Path.join(pdf_path, test_file)
    
    IO.puts("\\n🧪 Testing PDF extraction with: #{test_file}")
    
    # Check if file exists and is readable
    case File.stat(file_path) do
      {:ok, %File.Stat{size: size, access: access}} ->
        IO.puts("   File info: #{size} bytes, accessible: #{access != :none}")
        
        # Try direct extraction
        IO.puts("   Attempting direct extraction...")
        
        # Use our PDF extractor directly
        case GreenManTavern.Knowledge.PDFExtractor.extract_text(file_path) do
          {:ok, text} ->
            IO.puts("   ✅ PDF extraction SUCCESS!")
            IO.puts("   Extracted #{String.length(text)} characters")
            IO.puts("   First 200 chars: #{String.slice(text, 0, 200)}...")
            
            # Now try metadata
            case GreenManTavern.Knowledge.PDFExtractor.extract_metadata(file_path) do
              {:ok, metadata} ->
                IO.puts("   ✅ Metadata extraction SUCCESS!")
                IO.puts("   Metadata: #{inspect(metadata)}")
              {:error, meta_reason} ->
                IO.puts("   ⚠️ Metadata failed: #{inspect(meta_reason)}")
            end
            
          {:error, reason} ->
            IO.puts("   ❌ PDF extraction failed: #{inspect(reason)}")
            IO.puts("   Let's try an alternative approach...")
            
            # Alternative: Use System command with pdftotext if available
            IO.puts("   Trying alternative extraction method...")
            case System.cmd("which", ["pdftotext"]) do
              {_, 0} ->
                IO.puts("   pdftotext is available, using it...")
                case System.cmd("pdftotext", [file_path, "-"]) do
                  {output, 0} ->
                    IO.puts("   ✅ Alternative extraction worked!")
                    IO.puts("   Extracted #{String.length(output)} characters")
                  {error, _} ->
                    IO.puts("   ❌ pdftotext failed: #{error}")
                end
              _ ->
                IO.puts("   pdftotext not available")
            end
        end
        
      {:error, stat_reason} ->
        IO.puts("   ❌ Cannot access file: #{inspect(stat_reason)}")
    end
    
  {:error, reason} ->
    IO.puts("❌ Cannot access PDF directory: #{inspect(reason)}")
end
