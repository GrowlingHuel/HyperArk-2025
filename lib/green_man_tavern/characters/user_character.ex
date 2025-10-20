defmodule GreenManTavern.Characters.UserCharacter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_characters" do
    field :trust_level, :integer, default: 0
    field :first_interaction_at, :utc_datetime_usec
    field :last_interaction_at, :utc_datetime_usec
    field :interaction_count, :integer, default: 0
    field :is_trusted, :boolean, default: false

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :character, GreenManTavern.Characters.Character
  end

  @doc false
  def changeset(user_character, attrs) do
    user_character
    |> cast(attrs, [
      :user_id,
      :character_id,
      :trust_level,
      :first_interaction_at,
      :last_interaction_at,
      :interaction_count,
      :is_trusted
    ])
    |> validate_required([:user_id, :character_id])
    |> validate_number(:trust_level, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :character_id])
  end

  @doc """
  Increases trust level and updates interaction timestamps
  """
  def increase_trust(user_character, points \\ 1) do
    now = DateTime.utc_now()

    user_character
    |> change(%{
      trust_level: user_character.trust_level + points,
      last_interaction_at: now,
      interaction_count: user_character.interaction_count + 1,
      first_interaction_at: user_character.first_interaction_at || now
    })
    |> put_change(:is_trusted, user_character.trust_level + points >= get_trust_threshold(user_character))
  end

  defp get_trust_threshold(user_character) do
    case user_character.character.trust_requirement do
      "none" -> 0
      "basic" -> 20
      "intermediate" -> 50
      "advanced" -> 100
      _ -> 0
    end
  end
end
