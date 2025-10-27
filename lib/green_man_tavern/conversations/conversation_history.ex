defmodule GreenManTavern.Conversations.ConversationHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversation_history" do
    field :message_type, :string
    field :message_content, :string
    field :extracted_projects, {:array, :string}

    timestamps(type: :naive_datetime)

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :character, GreenManTavern.Characters.Character
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :user_id,
      :character_id,
      :message_type,
      :message_content,
      :extracted_projects
    ])
    |> validate_required([:user_id, :character_id, :message_type, :message_content])
    |> validate_inclusion(:message_type, ["user", "character"])
    |> validate_length(:message_content, max: 2000)
    |> sanitize_message_content()
  end

  # Sanitize message content to prevent XSS attacks
  defp sanitize_message_content(changeset) do
    case get_change(changeset, :message_content) do
      nil ->
        changeset

      content when is_binary(content) ->
        # Escape HTML to prevent XSS
        sanitized = Phoenix.HTML.html_escape(content) |> Phoenix.HTML.safe_to_string()
        put_change(changeset, :message_content, sanitized)

      _ ->
        changeset
    end
  end
end
