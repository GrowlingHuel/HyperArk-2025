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

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:systems, [:category])
    create index(:systems, [:system_type])
  end
end
