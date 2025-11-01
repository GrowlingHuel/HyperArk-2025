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
    # Note: Database uses :text type (unlimited length), so no length validation needed
    # Note: HTML escaping is handled at display time by HEEx templates for security
    # This ensures raw content is stored, and proper escaping happens in the view layer
  end
end
