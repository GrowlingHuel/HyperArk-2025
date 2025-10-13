defmodule GreenManTavern.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements) do
      add :name, :string, null: false
      add :description, :text
      add :badge_icon, :string
      add :unlock_criteria, :jsonb, default: fragment("'{}'::jsonb")
      add :xp_value, :integer, default: 0
      add :rarity, :string

      timestamps()
    end

    create unique_index(:achievements, [:name])
  end
end
