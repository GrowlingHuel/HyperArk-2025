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

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create unique_index(:achievements, [:name])
  end
end
