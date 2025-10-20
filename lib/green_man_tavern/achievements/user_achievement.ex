defmodule GreenManTavern.Achievements.UserAchievement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_achievements" do
    field :unlocked_at, :utc_datetime_usec

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :achievement, GreenManTavern.Achievements.Achievement
  end

  @doc false
  def changeset(user_achievement, attrs) do
    user_achievement
    |> cast(attrs, [:user_id, :achievement_id, :unlocked_at])
    |> validate_required([:user_id, :achievement_id, :unlocked_at])
    |> unique_constraint([:user_id, :achievement_id])
  end
end
