defmodule GreenManTavern.Documents.Document do
  @moduledoc """
  Schema for managing PDF documents in the knowledge base.

  Documents represent uploaded PDF files that have been processed
  and chunked for use with MindsDB agents. Each document contains
  metadata about the original file and references to its chunks.

  ## Fields

  - `id` - UUID primary key
  - `title` - Human-readable title of the document
  - `source_file` - Original filename of the uploaded PDF
  - `file_path` - Local path where the PDF is stored
  - `total_chunks` - Number of text chunks created from the document
  - `processed_at` - Timestamp when the document was processed
  - `metadata` - Additional metadata (category, author, date, etc.)
  - `inserted_at`, `updated_at` - Standard timestamps

  ## Associations

  - `has_many :chunks` - All text chunks belonging to this document
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias GreenManTavern.Documents.DocumentChunk

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "documents" do
    field :title, :string
    field :source_file, :string
    field :file_path, :string
    field :total_chunks, :integer, default: 0
    field :processed_at, :utc_datetime
    field :metadata, :map, default: %{}

    timestamps()

    # Associations
    has_many :chunks, DocumentChunk, foreign_key: :document_id
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:title, :source_file, :file_path, :total_chunks, :processed_at, :metadata])
    |> validate_required([:title, :source_file, :file_path])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:source_file, min: 1, max: 255)
    |> validate_length(:file_path, min: 1, max: 500)
    |> validate_number(:total_chunks, greater_than_or_equal_to: 0)
    |> validate_metadata()
  end

  @doc """
  Creates a changeset for a new document with default values.
  """
  def create_changeset(document, attrs) do
    document
    |> cast(attrs, [:title, :source_file, :file_path, :metadata])
    |> validate_required([:title, :source_file, :file_path])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:source_file, min: 1, max: 255)
    |> validate_length(:file_path, min: 1, max: 500)
    |> put_change(:total_chunks, 0)
    |> put_change(:processed_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_metadata()
  end

  @doc """
  Updates the total chunks count for a document.
  """
  def update_chunks_count_changeset(document, count) do
    document
    |> cast(%{total_chunks: count}, [:total_chunks])
    |> validate_number(:total_chunks, greater_than_or_equal_to: 0)
  end

  @doc """
  Marks a document as processed.
  """
  def mark_processed_changeset(document) do
    document
    |> cast(%{processed_at: DateTime.utc_now() |> DateTime.truncate(:second)}, [:processed_at])
  end

  @doc """
  Updates document metadata.
  """
  def update_metadata_changeset(document, metadata) do
    document
    |> cast(%{metadata: metadata}, [:metadata])
    |> validate_metadata()
  end

  # Private functions
  defp validate_metadata(changeset) do
    # Metadata validation is optional - we just ensure it's a map if present
    case get_change(changeset, :metadata) do
      nil ->
        changeset

      metadata when is_map(metadata) ->
        changeset

      _ ->
        add_error(changeset, :metadata, "must be a map")
    end
  end

  defp validate_metadata_structure(metadata) do
    # Check for required fields
    required_fields = [:category]
    missing_fields = Enum.filter(required_fields, &(not Map.has_key?(metadata, &1)))

    if Enum.empty?(missing_fields) do
      # Validate field values
      cond do
        not is_binary(metadata[:category]) ->
          {:error, "category must be a string"}

        not is_nil(metadata[:author]) and not is_binary(metadata[:author]) ->
          {:error, "author must be a string"}

        not is_nil(metadata[:date]) and not is_binary(metadata[:date]) ->
          {:error, "date must be a string"}

        not is_nil(metadata[:tags]) and not is_list(metadata[:tags]) ->
          {:error, "tags must be a list"}

        true ->
          :ok
      end
    else
      {:error, "missing required fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end
end
