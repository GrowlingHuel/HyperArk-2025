defmodule GreenManTavern.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string, null: false
      add :archetype, :string, null: false
      add :description, :text
      add :focus_area, :string
      add :personality_traits, :jsonb, default: fragment("'[]'::jsonb")
      add :icon_name, :string
      add :color_scheme, :string
      add :trust_requirement, :string, default: "none"
      add :mindsdb_agent_name, :string

      timestamps()
    end

    create unique_index(:characters, [:name])
  end
end
