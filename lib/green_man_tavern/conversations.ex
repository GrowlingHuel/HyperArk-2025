defmodule GreenManTavern.Conversations do
  @moduledoc """
  The Conversations context for managing conversation history.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Conversations.ConversationHistory

  @doc """
  Returns the list of conversation entries.

  ## Examples

      iex> list_conversation_entries()
      [%ConversationHistory{}, ...]

  """
  def list_conversation_entries do
    Repo.all(ConversationHistory)
  end

  @doc """
  Gets a single conversation entry.

  Raises `Ecto.NoResultsError` if the Conversation entry does not exist.

  ## Examples

      iex> get_conversation_entry!(123)
      %ConversationHistory{}

      iex> get_conversation_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation_entry!(id), do: Repo.get!(ConversationHistory, id)

  @doc """
  Creates a conversation entry.

  ## Examples

      iex> create_conversation_entry(%{field: value})
      {:ok, %ConversationHistory{}}

      iex> create_conversation_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation_entry(attrs \\ %{}) do
    %ConversationHistory{}
    |> ConversationHistory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation entry.

  ## Examples

      iex> update_conversation_entry(conversation, %{field: new_value})
      {:ok, %ConversationHistory{}}

      iex> update_conversation_entry(conversation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation_entry(%ConversationHistory{} = conversation, attrs) do
    conversation
    |> ConversationHistory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a conversation entry.

  ## Examples

      iex> delete_conversation_entry(conversation)
      {:ok, %ConversationHistory{}}

      iex> delete_conversation_entry(conversation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation_entry(%ConversationHistory{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation entry changes.

  ## Examples

      iex> change_conversation_entry(conversation)
      %Ecto.Changeset{data: %ConversationHistory{}}

  """
  def change_conversation_entry(%ConversationHistory{} = conversation, attrs \\ %{}) do
    ConversationHistory.changeset(conversation, attrs)
  end

  @doc """
  Gets recent conversation between a user and character.

  ## Examples

      iex> get_recent_conversation(1, 2, 10)
      [%ConversationHistory{}, ...]

  """
  def get_recent_conversation(user_id, character_id, limit \\ 20) do
    from(ch in ConversationHistory,
      where: ch.user_id == ^user_id and ch.character_id == ^character_id,
      order_by: [desc: ch.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets conversation history for a user with a specific character.

  ## Examples

      iex> get_user_character_conversation(1, 2)
      [%ConversationHistory{}, ...]

  """
  def get_user_character_conversation(user_id, character_id) do
    from(ch in ConversationHistory,
      where: ch.user_id == ^user_id and ch.character_id == ^character_id,
      order_by: [asc: ch.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets all conversations for a user.

  ## Examples

      iex> get_user_conversations(1)
      [%ConversationHistory{}, ...]

  """
  def get_user_conversations(user_id) do
    from(ch in ConversationHistory,
      where: ch.user_id == ^user_id,
      order_by: [desc: ch.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets all conversations for a character.

  ## Examples

      iex> get_character_conversations(1)
      [%ConversationHistory{}, ...]

  """
  def get_character_conversations(character_id) do
    from(ch in ConversationHistory,
      where: ch.character_id == ^character_id,
      order_by: [desc: ch.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Deletes old conversation entries older than the specified days.

  ## Examples

      iex> cleanup_old_conversations(30)
      {5, nil}

  """
  def cleanup_old_conversations(days) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    from(ch in ConversationHistory,
      where: ch.inserted_at < ^cutoff_date
    )
    |> Repo.delete_all()
  end
end
