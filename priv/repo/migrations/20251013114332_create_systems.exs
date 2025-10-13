defmodule GreenManTavern.Repo.Migrations.CreateSystems do
  use Ecto.Migration

  def change do
    create table(:systems) do
      add :name, :string, null: false
      add :system_type, :string, null: false
      add :category, :string, null: false
      add :description, :text
      add :requirements, :text
      add :default_inputs, :jsonb, default: fragment("'[]'::jsonb")
      add :default_outputs, :jsonb, default: fragment("'[]'::jsonb")
      add :icon_name, :string
      add :space_required, :string
      add :skill_level, :string

      timestamps()
    end

    create index(:systems, [:category])
    create index(:systems, [:system_type])
  end
end
