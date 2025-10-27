defmodule GreenManTavern.Repo.Migrations.CreateDocumentsAndChunks do
  use Ecto.Migration

  def change do
    # Create documents table
    create table(:documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :source_file, :string, null: false
      add :file_path, :string, null: false
      add :total_chunks, :integer, default: 0, null: false
      add :processed_at, :utc_datetime
      add :metadata, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    # Create document_chunks table
    create table(:document_chunks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :document_id, references(:documents, type: :binary_id, on_delete: :delete_all),
        null: false

      add :content, :text, null: false
      add :chunk_index, :integer, null: false
      add :character_count, :integer, default: 0, null: false
      add :metadata, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    # Create indexes for better performance
    create index(:documents, [:processed_at])
    create index(:documents, [:title])
    create index(:documents, [:source_file])

    create index(:document_chunks, [:document_id])
    create index(:document_chunks, [:chunk_index])
    create index(:document_chunks, [:document_id, :chunk_index])
  end
end
