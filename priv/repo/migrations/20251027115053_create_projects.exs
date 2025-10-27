defmodule GreenManTavern.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :description, :text
      add :category, :string, null: false # food, water, waste, energy
      add :inputs, :jsonb, default: fragment("'{}'::jsonb")
      add :outputs, :jsonb, default: fragment("'{}'::jsonb")
      add :constraints, {:array, :string}, default: []
      add :icon_name, :string
      add :skill_level, :string # beginner, intermediate, advanced

      timestamps(type: :naive_datetime, updated_at: false)
    end

    create index(:projects, [:category])
    create index(:projects, [:skill_level])
    create index(:projects, [:name])
  end
end
