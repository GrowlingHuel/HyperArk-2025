defmodule GreenManTavern.Documents.DocumentChunk do
  @moduledoc """
  Schema for managing text chunks from PDF documents.

  DocumentChunk represents a piece of text extracted from a PDF document,
  typically around 1000 words, that can be used for AI agent training
  and knowledge base queries.

  ## Fields

  - `id` - UUID primary key
  - `document_id` - Foreign key reference to the parent document
  - `content` - The actual text content of the chunk
  - `chunk_index` - Order of this chunk within the document (0-based)
  - `character_count` - Number of characters in the chunk
  - `metadata` - Additional metadata (page numbers, section headings, etc.)
  - `inserted_at`, `updated_at` - Standard timestamps

  ## Associations

  - `belongs_to :document` - The parent document this chunk belongs to
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias GreenManTavern.Documents.Document

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "document_chunks" do
    field :content, :string
    field :chunk_index, :integer
    field :character_count, :integer
    field :metadata, :map, default: %{}

    timestamps()

    # Associations
    belongs_to :document, Document, foreign_key: :document_id
  end

  @doc false
  def changeset(chunk, attrs) do
    chunk
    |> cast(attrs, [:document_id, :content, :chunk_index, :character_count, :metadata])
    |> validate_required([:document_id, :content, :chunk_index])
    |> validate_length(:content, min: 1)
    |> validate_number(:chunk_index, greater_than_or_equal_to: 0)
    |> validate_number(:character_count, greater_than_or_equal_to: 0)
    |> validate_metadata()
    |> foreign_key_constraint(:document_id)
  end

  @doc """
  Creates a changeset for a new chunk with automatic character count.
  """
  def create_changeset(chunk, attrs) do
    chunk
    |> cast(attrs, [:document_id, :content, :chunk_index, :metadata])
    |> validate_required([:document_id, :content, :chunk_index])
    |> validate_length(:content, min: 1)
    |> validate_number(:chunk_index, greater_than_or_equal_to: 0)
    |> put_change(:character_count, calculate_character_count(attrs[:content]))
    |> validate_metadata()
    |> foreign_key_constraint(:document_id)
  end

  @doc """
  Updates chunk metadata.
  """
  def update_metadata_changeset(chunk, metadata) do
    chunk
    |> cast(%{metadata: metadata}, [:metadata])
    |> validate_metadata()
  end

  @doc """
  Updates chunk content and recalculates character count.
  """
  def update_content_changeset(chunk, content) do
    chunk
    |> cast(%{content: content}, [:content])
    |> validate_length(:content, min: 1)
    |> put_change(:character_count, calculate_character_count(content))
  end

  # Private functions

  defp calculate_character_count(content) when is_binary(content) do
    String.length(content)
  end

  defp calculate_character_count(_), do: 0

  defp validate_metadata(changeset) do
    case get_field(changeset, :metadata) do
      nil ->
        changeset

      metadata when is_map(metadata) ->
        # Validate metadata structure
        case validate_metadata_structure(metadata) do
          :ok ->
            changeset
          {:error, reason} ->
            add_error(changeset, :metadata, reason)
        end

      _ ->
        add_error(changeset, :metadata, "must be a map")
    end
  end

  defp validate_metadata_structure(metadata) do
    # Validate field values
    cond do
      not is_nil(metadata[:page_number]) and not is_integer(metadata[:page_number]) ->
        {:error, "page_number must be an integer"}

      not is_nil(metadata[:section_heading]) and not is_binary(metadata[:section_heading]) ->
        {:error, "section_heading must be a string"}

      not is_nil(metadata[:word_count]) and not is_integer(metadata[:word_count]) ->
        {:error, "word_count must be an integer"}

      not is_nil(metadata[:keywords]) and not is_list(metadata[:keywords]) ->
        {:error, "keywords must be a list"}

      true ->
        :ok
    end
  end
end
