defmodule GreenManTavern.Repo.Migrations.CreateDiagrams do
  use Ecto.Migration

  def change do
    create table(:diagrams) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :nodes, :jsonb, default: fragment("'{}'::jsonb")
      add :edges, :jsonb, default: fragment("'{}'::jsonb")

      timestamps(type: :naive_datetime, updated_at: false)
    end

    create index(:diagrams, [:user_id])
    create index(:diagrams, [:name])
    create index(:diagrams, [:inserted_at])
  end
end
