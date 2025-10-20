defmodule GreenManTavern.Quests.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quests" do
    field :title, :string
    field :description, :string
    field :quest_type, :string
    field :difficulty, :string
    field :xp_reward, :integer, default: 0
    field :required_systems, {:array, :integer}
    field :instructions, {:array, :string}
    field :success_criteria, :map

    belongs_to :character, GreenManTavern.Characters.Character
    has_many :user_quests, GreenManTavern.Quests.UserQuest
  end

  @doc false
  def changeset(quest, attrs) do
    quest
    |> cast(attrs, [
      :title,
      :description,
      :character_id,
      :quest_type,
      :difficulty,
      :xp_reward,
      :required_systems,
      :instructions,
      :success_criteria
    ])
    |> validate_required([:title])
    |> validate_inclusion(:quest_type, [
      "tutorial",
      "implementation",
      "maintenance",
      "learning",
      "community",
      "challenge"
    ])
    |> validate_inclusion(:difficulty, ["easy", "medium", "hard"])
    |> validate_number(:xp_reward, greater_than_or_equal_to: 0)
  end
end
