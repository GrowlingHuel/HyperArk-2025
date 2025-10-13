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

      timestamps()
    end

    create index(:quests, [:character_id])
    create index(:quests, [:quest_type])
    create index(:quests, [:difficulty])
  end
end
