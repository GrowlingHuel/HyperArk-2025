defmodule GreenManTavern.Achievements.Achievement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "achievements" do
    field :name, :string
    field :description, :string
    field :badge_icon, :string
    field :unlock_criteria, :map
    field :xp_value, :integer, default: 0
    field :rarity, :string

    has_many :user_achievements, GreenManTavern.Achievements.UserAchievement

    timestamps()
  end

  @doc false
  def changeset(achievement, attrs) do
    achievement
    |> cast(attrs, [:name, :description, :badge_icon, :unlock_criteria, :xp_value, :rarity])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_inclusion(:rarity, ["common", "rare", "epic", "legendary"])
    |> validate_number(:xp_value, greater_than_or_equal_to: 0)
  end
end
