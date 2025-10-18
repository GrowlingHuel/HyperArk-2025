defmodule GreenManTavern.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  schema "characters" do
    field :name, :string
    field :archetype, :string
    field :description, :string
    field :focus_area, :string
    field :personality_traits, {:array, :string}
    field :icon_name, :string
    field :color_scheme, :string
    field :trust_requirement, :string
    field :mindsdb_agent_name, :string

    has_many :user_characters, GreenManTavern.Characters.UserCharacter
    has_many :quests, GreenManTavern.Quests.Quest
    has_many :conversations, GreenManTavern.Conversations.ConversationHistory

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :name,
      :archetype,
      :description,
      :focus_area,
      :personality_traits,
      :icon_name,
      :color_scheme,
      :trust_requirement,
      :mindsdb_agent_name
    ])
    |> validate_required([:name, :archetype])
    |> unique_constraint(:name)
    |> validate_inclusion(:trust_requirement, ["none", "basic", "intermediate", "advanced"])
  end
end
