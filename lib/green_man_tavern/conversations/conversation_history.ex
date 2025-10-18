defmodule GreenManTavern.Conversations.ConversationHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversation_history" do
    field :message_type, :string
    field :message_content, :string
    field :extracted_projects, {:array, :string}

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :character, GreenManTavern.Characters.Character

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user_id, :character_id, :message_type, :message_content, :extracted_projects])
    |> validate_required([:user_id, :character_id, :message_type, :message_content])
    |> validate_inclusion(:message_type, ["user", "agent"])
  end
end
