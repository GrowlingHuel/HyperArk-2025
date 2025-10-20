defmodule GreenManTavern.Conversations.ConversationHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversation_history" do
    field :message_type, :string
    field :content, :string
    field :timestamp, :utc_datetime
    field :extracted_projects, {:array, :string}

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :character, GreenManTavern.Characters.Character
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user_id, :character_id, :message_type, :content, :timestamp, :extracted_projects])
    |> validate_required([:user_id, :character_id, :message_type, :content])
    |> validate_inclusion(:message_type, ["user", "character"])
  end
end
