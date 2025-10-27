defmodule GreenManTavern.Conversations do
  @moduledoc """
  The Conversations context for managing conversation history.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Conversations.ConversationHistory

  @doc """
  Returns the list of conversation entries for the given user.

  This function is user-scoped for security and privacy.

  ## Examples

      iex> list_conversation_entries(123)
      [%ConversationHistory{}, ...]

  """
  def list_conversation_entries(user_id) when is_integer(user_id) do
    from(ch in ConversationHistory, where: ch.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single conversation entry for the given user.

  Raises `Ecto.NoResultsError` if the Conversation entry does not exist or
  does not belong to the given user.

  ## Examples

      iex> get_conversation_entry!(123, 456)
      %ConversationHistory{}

      iex> get_conversation_entry!(456, 456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation_entry!(id, user_id) when is_integer(id) and is_integer(user_id) do
    Repo.get_by!(ConversationHistory, id: id, user_id: user_id)
  end

  @doc """
  Creates a conversation entry for the given user.

  This function requires user_id to be present in attrs for security.
  The user_id must match the authenticated user to prevent spoofing.

  ## Examples

      iex> create_conversation_entry(%{user_id: 1, field: value})
      {:ok, %ConversationHistory{}}

      iex> create_conversation_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  ## Security

  This function requires user_id to be set in attrs. Callers should
  explicitly set user_id from the authenticated user to prevent spoofing.
  """
  def create_conversation_entry(attrs \\ %{}) do
    # Security: Ensure user_id is present and valid
    case Map.get(attrs, :user_id) do
      nil ->
        # Create a changeset to get proper error handling
        changeset = %ConversationHistory{} |> ConversationHistory.changeset(attrs)
        {:error, %{changeset | errors: [{:user_id, {"is required for security", []}} | changeset.errors]}}
      
      user_id when is_integer(user_id) ->
        %ConversationHistory{}
        |> ConversationHistory.changeset(attrs)
        |> Repo.insert()
      
      _ ->
        changeset = %ConversationHistory{} |> ConversationHistory.changeset(attrs)
        {:error, %{changeset | errors: [{:user_id, {"must be an integer", []}} | changeset.errors]}}
    end
  end

  @doc """
  Updates a conversation entry for the given user.

  This function verifies ownership before updating for security.

  ## Examples

      iex> update_conversation_entry(conversation, user_id, %{field: new_value})
      {:ok, %ConversationHistory{}}

      iex> update_conversation_entry(conversation, user_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation_entry(%ConversationHistory{} = conversation, user_id, attrs)
      when is_integer(user_id) do
    # Verify ownership before updating
    if conversation.user_id == user_id do
      conversation
      |> ConversationHistory.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a conversation entry for the given user.

  This function verifies ownership before deleting for security.

  ## Examples

      iex> delete_conversation_entry(conversation, user_id)
      {:ok, %ConversationHistory{}}

      iex> delete_conversation_entry(conversation, user_id)
      {:error, :unauthorized}

  """
  def delete_conversation_entry(%ConversationHistory{} = conversation, user_id)
      when is_integer(user_id) do
    # Verify ownership before deleting
    if conversation.user_id == user_id do
      Repo.delete(conversation)
    else
      {:error, :unauthorized}
    end
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
  Gets all conversations for a character scoped to the given user.

  This function is user-scoped for security and privacy.

  ## Examples

      iex> get_character_conversations(123, 1)
      [%ConversationHistory{}, ...]

  """
  def get_character_conversations(user_id, character_id)
      when is_integer(user_id) and is_integer(character_id) do
    from(ch in ConversationHistory,
      where: ch.user_id == ^user_id and ch.character_id == ^character_id,
      order_by: [desc: ch.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Deletes old conversation entries older than the specified days.

  WARNING: This is an admin-only function that affects ALL users' data.
  Use with extreme caution in production.

  ## Examples

      iex> cleanup_old_conversations(30)
      {5, nil}

  """
  def cleanup_old_conversations(days) when is_integer(days) and days > 0 do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    from(ch in ConversationHistory,
      where: ch.inserted_at < ^cutoff_date
    )
    |> Repo.delete_all()
  end
end
