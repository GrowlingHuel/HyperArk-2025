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
    # Support both formats - map for new format, array for existing
    field :steps, :map

    belongs_to :character, GreenManTavern.Characters.Character
    has_many :user_quests, GreenManTavern.Quests.UserQuest

    timestamps()
  end

  @difficulties ["easy", "medium", "hard"]
  @quest_types ["tutorial", "implementation", "maintenance", "learning", "community", "challenge", "system_opportunity"]

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
      :success_criteria,
      :steps
    ])
    |> validate_required([:title, :description, :difficulty, :quest_type])
    |> validate_inclusion(:quest_type, @quest_types)
    |> validate_inclusion(:difficulty, @difficulties)
    |> validate_number(:xp_reward, greater_than_or_equal_to: 0)
  end
end
