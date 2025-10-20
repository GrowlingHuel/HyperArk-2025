defmodule GreenManTavern.Repo.Migrations.CreateQuests do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :title, :string, null: false
      add :description, :text
      add :character_id, references(:characters, on_delete: :nilify_all)
      add :quest_type, :string
      add :difficulty, :string
      add :xp_reward, :integer, default: 0
      add :required_systems, :jsonb, default: fragment("'[]'::jsonb")
      add :instructions, :jsonb, default: fragment("'[]'::jsonb")
      add :success_criteria, :jsonb, default: fragment("'{}'::jsonb")

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:quests, [:character_id])
    create index(:quests, [:quest_type])
    create index(:quests, [:difficulty])
  end
end
