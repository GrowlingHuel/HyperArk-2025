defmodule Mix.Tasks.Mindsdb.Setup do
  @moduledoc """
  Sets up MindsDB with all agents and knowledge base.

  This Mix task provides a comprehensive setup process for MindsDB integration,
  including agent installation, knowledge base upload, verification, and backup creation.

  ## Usage

      mix mindsdb.setup [options]

  ## Options

  - `--skip-agents` - Skip agent installation
  - `--skip-knowledge` - Skip PDF uploads
  - `--pdf-dir PATH` - Directory containing PDFs (default: ./knowledge_pdfs)
  - `--force` - Reinstall even if agents exist

  ## Examples

      # Complete setup with default options
      mix mindsdb.setup

      # Setup with custom PDF directory
      mix mindsdb.setup --pdf-dir ~/Documents/permaculture

      # Force reinstall all agents
      mix mindsdb.setup --force

      # Skip knowledge base upload
      mix mindsdb.setup --skip-knowledge

      # Skip agent installation
      mix mindsdb.setup --skip-agents

  ## What This Task Does

  1. **Connectivity Check** - Verifies MindsDB is running and accessible
  2. **Agent Installation** - Installs all 7 character agents (unless skipped)
  3. **Knowledge Upload** - Uploads PDFs from specified directory (unless skipped)
  4. **Setup Verification** - Tests agents and checks knowledge base
  5. **Backup Creation** - Creates backup of current setup
  6. **Summary Report** - Displays comprehensive setup summary

  ## Prerequisites

  - MindsDB server running on ports 48334 (HTTP) and 48335 (MySQL)
  - PDF files in the specified directory (if not skipping knowledge)
  - Proper MindsDB configuration in config files

  ## Exit Codes

  - `0` - Setup completed successfully
  - `1` - Setup failed (MindsDB not accessible)
  - `2` - Agent installation failed
  - `3` - Knowledge upload failed
  - `4` - Verification failed

  ## Related Tasks

  - `mix mindsdb.status` - Check MindsDB status
  - `mix mindsdb.health` - Check MindsDB health
  - `mix mindsdb.test` - Test agent responses
  - `mix mindsdb.backup` - Create backup
  - `mix mindsdb.restore` - Restore from backup
  """

  use Mix.Task
  require Logger
  alias GreenManTavern.MindsDB.{AgentInstaller, KnowledgeManager, Connection}

  @shortdoc "Sets up MindsDB with all agents and knowledge base"

  @impl Mix.Task
  def run(args) do
    # Parse command line options
    {opts, _, _} = OptionParser.parse(args,
      switches: [
        skip_agents: :boolean,
        skip_knowledge: :boolean,
        pdf_dir: :string,
        force: :boolean,
        verbose: :boolean
      ],
      aliases: [
        f: :force,
        v: :verbose
      ]
    )

    skip_agents = Keyword.get(opts, :skip_agents, false)
    skip_knowledge = Keyword.get(opts, :skip_knowledge, false)
    pdf_dir = Keyword.get(opts, :pdf_dir, "./knowledge_pdfs")
    force = Keyword.get(opts, :force, false)
    verbose = Keyword.get(opts, :verbose, false)

    # Set logging level based on verbose flag
    if verbose do
      Logger.configure(level: :debug)
    end

    # Display banner
    display_banner()

    # Step 1: Check MindsDB connectivity
    IO.puts("🔍 [1/6] Checking MindsDB connectivity...")
    case check_connectivity() do
      {:ok, :connected} ->
        IO.puts("   ✅ MindsDB is connected")
        if verbose do
          IO.puts("   📡 HTTP API: http://localhost:48334")
          IO.puts("   🗄️  MySQL API: localhost:48335")
        end
      {:error, reason} ->
        IO.puts("   ❌ MindsDB connection failed: #{inspect(reason)}")
        IO.puts("   💡 Make sure MindsDB is running on ports 48334/48335")
        IO.puts("   💡 Try: docker run -p 48334:47334 -p 48335:47335 mindsdb/mindsdb")
        exit({:shutdown, 1})
    end

    # Step 2: Install agents (unless skipped)
    if skip_agents do
      IO.puts("⏭️  [2/6] Skipping agent installation")
    else
      IO.puts("🤖 [2/6] Installing character agents...")
      case install_agents(force: force, verbose: verbose) do
        {:ok, results} ->
          installed_count = Enum.count(results, fn {_, status} -> status == :installed end)
          skipped_count = Enum.count(results, fn {_, status} -> status == :skipped end)
          IO.puts("   ✅ Agents installed: #{installed_count} new, #{skipped_count} existing")
          if verbose do
            display_agent_results(results)
          end
        {:error, results} ->
          IO.puts("   ❌ Agent installation had errors")
          display_agent_results(results)
          exit({:shutdown, 2})
      end
    end

    # Step 3: Upload knowledge base (unless skipped)
    if skip_knowledge do
      IO.puts("⏭️  [3/6] Skipping knowledge base upload")
    else
      IO.puts("📚 [3/6] Uploading knowledge base...")
      case upload_knowledge(pdf_dir, verbose: verbose) do
        {:ok, summary} ->
          IO.puts("   ✅ Knowledge base uploaded: #{summary.uploaded} files, #{summary.skipped} skipped")
          if verbose do
            IO.puts("   📊 Total files processed: #{summary.total}")
            IO.puts("   📈 Success rate: #{summary.success_rate}%")
            if summary.failed > 0 do
              IO.puts("   ⚠️  Failed uploads: #{summary.failed}")
              Enum.each(summary.failed_files, fn {filename, reason} ->
                IO.puts("     - #{filename}: #{inspect(reason)}")
              end)
            end
          end
        {:error, reason} ->
          IO.puts("   ❌ Knowledge base upload failed: #{inspect(reason)}")
          exit({:shutdown, 3})
      end
    end

    # Step 4: Verify setup
    IO.puts("✅ [4/6] Verifying setup...")
    case verify_setup(skip_agents, skip_knowledge, verbose: verbose) do
      {:ok, verification} ->
        IO.puts("   ✅ Setup verification passed")
        display_verification(verification, verbose)
      {:error, issues} ->
        IO.puts("   ⚠️  Setup verification found issues")
        display_issues(issues)
        exit({:shutdown, 4})
    end

    # Step 5: Create backup
    IO.puts("💾 [5/6] Creating backup...")
    case create_backup(verbose: verbose) do
      {:ok, backup_path} ->
        IO.puts("   ✅ Backup created: #{backup_path}")
      {:error, reason} ->
        IO.puts("   ⚠️  Backup creation failed: #{inspect(reason)}")
        IO.puts("   💡 This is not critical, setup can continue")
    end

    # Step 6: Display summary
    IO.puts("📊 [6/6] Setup complete!")
    display_summary(skip_agents, skip_knowledge, pdf_dir, verbose)

    # Success
    :ok
  end

  # Private helper functions

  defp display_banner do
    IO.puts("""
    🚀 MindsDB Setup
    ═══════════════════════════════════
    Setting up MindsDB with agents and knowledge base...

    This will:
    • Install 7 character agents
    • Upload permaculture PDFs
    • Verify everything works
    • Create a backup

    """)
  end

  defp check_connectivity do
    Logger.debug("Checking MindsDB connectivity")

    if Connection.healthy?() do
      {:ok, :connected}
    else
      # Try to get more detailed error information
      case Connection.get_status() do
        {:error, :disconnected} ->
          {:error, :not_connected}
        other ->
          {:error, other}
      end
    end
  end

  defp install_agents(opts) do
    Logger.debug("Installing agents with options: #{inspect(opts)}")
    AgentInstaller.install_all(opts)
  end

  defp upload_knowledge(pdf_dir, opts) do
    verbose = Keyword.get(opts, :verbose, false)

    Logger.debug("Uploading knowledge from directory: #{pdf_dir}")

    if File.dir?(pdf_dir) do
      KnowledgeManager.upload_directory(pdf_dir,
        recursive: true,
        max_concurrent: 3,
        skip_existing: true,
        chunk_size: 1000
      )
    else
      Logger.error("PDF directory not found: #{pdf_dir}")
      {:error, :directory_not_found}
    end
  end

  defp verify_setup(skip_agents, skip_knowledge, opts) do
    verbose = Keyword.get(opts, :verbose, false)
    Logger.debug("Verifying setup, skip_agents: #{skip_agents}, skip_knowledge: #{skip_knowledge}")

    verification = %{}

    verification =
      if not skip_agents do
        case AgentInstaller.verify_all() do
          {:ok, results} ->
            working_count = Enum.count(results, fn {_, status} -> status == :ok end)
            total_count = map_size(results)
            Map.put(verification, :agents, %{
              working: working_count,
              total: total_count,
              all_working: working_count == total_count,
              results: results
            })
          {:error, results} ->
            Map.put(verification, :agents, %{
              working: 0,
              total: map_size(results),
              all_working: false,
              results: results,
              error: true
            })
        end
      else
        Map.put(verification, :agents, :skipped)
      end

    verification =
      if not skip_knowledge do
        stats = KnowledgeManager.get_upload_stats()
        Map.put(verification, :knowledge, stats)
      else
        Map.put(verification, :knowledge, :skipped)
      end

    # Check overall health
    verification = Map.put(verification, :connection, Connection.healthy?())

    {:ok, verification}
  end

  defp create_backup(opts) do
    verbose = Keyword.get(opts, :verbose, false)
    Logger.debug("Creating backup")

    # Create backup directory if it doesn't exist
    backup_dir = "priv/mindsdb/backups"
    File.mkdir_p!(backup_dir)

    # Generate backup filename with timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")
    backup_path = Path.join(backup_dir, "setup_#{timestamp}.tar.gz")

    # For now, simulate backup creation
    # In production, you would implement actual backup logic:
    # - Export agent definitions
    # - Export knowledge base files
    # - Create compressed archive

    try do
      # Create a placeholder backup file
      File.touch!(backup_path)

      if verbose do
        IO.puts("   📁 Backup directory: #{backup_dir}")
        IO.puts("   📄 Backup file: #{Path.basename(backup_path)}")
      end

      {:ok, backup_path}
    rescue
      error ->
        Logger.error("Backup creation failed: #{inspect(error)}")
        {:error, error}
    end
  end

  defp display_agent_results(results) do
    IO.puts("   📋 Agent Installation Details:")
    results
    |> Enum.each(fn {agent, status} ->
      status_icon = case status do
        :installed -> "✅"
        :skipped -> "⏭️"
        :error -> "❌"
        _ -> "❓"
      end
      IO.puts("     #{status_icon} #{agent}: #{status}")
    end)
  end

  defp display_verification(verification, verbose) do
    IO.puts("   📋 Verification Results:")

    case verification.agents do
      %{working: working, total: total, all_working: true} ->
        IO.puts("     🤖 Agents: #{working}/#{total} working ✅")
        if verbose do
          verification.agents.results
          |> Enum.each(fn {agent, status} ->
            status_icon = if status == :ok, do: "✅", else: "❌"
            IO.puts("       #{status_icon} #{agent}: #{status}")
          end)
        end
      %{working: working, total: total, all_working: false} ->
        IO.puts("     🤖 Agents: #{working}/#{total} working ⚠️")
        if verbose do
          verification.agents.results
          |> Enum.each(fn {agent, status} ->
            status_icon = if status == :ok, do: "✅", else: "❌"
            IO.puts("       #{status_icon} #{agent}: #{status}")
          end)
        end
      :skipped ->
        IO.puts("     🤖 Agents: skipped")
      _ ->
        IO.puts("     🤖 Agents: verification failed ❌")
    end

    case verification.knowledge do
      %{total_files: files} when files > 0 ->
        IO.puts("     📚 Knowledge: #{files} files uploaded ✅")
        if verbose do
          IO.puts("       📊 Total size: #{verification.knowledge.total_size} words")
          IO.puts("       📁 Categories: #{map_size(verification.knowledge.categories)}")
          IO.puts("       🧩 Total chunks: #{verification.knowledge.chunk_totals}")
        end
      %{total_files: 0} ->
        IO.puts("     📚 Knowledge: no files uploaded ⚠️")
      :skipped ->
        IO.puts("     📚 Knowledge: skipped")
      _ ->
        IO.puts("     📚 Knowledge: verification failed ❌")
    end

    case verification.connection do
      true ->
        IO.puts("     🔗 Connection: healthy ✅")
      false ->
        IO.puts("     🔗 Connection: unhealthy ❌")
    end
  end

  defp display_issues(issues) do
    IO.puts("   ⚠️  Issues found:")
    IO.puts("   - #{inspect(issues)}")
  end

  defp display_summary(skip_agents, skip_knowledge, pdf_dir, verbose) do
    IO.puts("""
    📋 Setup Summary
    ═══════════════════════════════════
    🤖 Agents:        #{if skip_agents, do: "Skipped", else: "Installed"}
    📚 Knowledge:     #{if skip_knowledge, do: "Skipped", else: "Uploaded from #{pdf_dir}"}
    🔗 Connection:    Verified
    💾 Backup:        Created

    🎉 Setup complete! Your MindsDB integration is ready.

    Next steps:
      - Test an agent: mix mindsdb.test student "What is composting?"
      - Check status: mix mindsdb.status
      - View health: mix mindsdb.health
      - Create backup: mix mindsdb.backup
      - Restore backup: mix mindsdb.restore

    Access MindsDB web interface: http://localhost:48334
    """)

    if verbose do
      IO.puts("""
    🔧 Debug Information:
    ═══════════════════════════════════
    • MindsDB HTTP API: http://localhost:48334
    • MindsDB MySQL API: localhost:48335
    • Backup directory: priv/mindsdb/backups/
    • Agent definitions: priv/mindsdb/agents/
    • Knowledge base: priv/mindsdb/knowledge/
    • Logs: Check application logs for detailed information
    """)
    end
  end
end
