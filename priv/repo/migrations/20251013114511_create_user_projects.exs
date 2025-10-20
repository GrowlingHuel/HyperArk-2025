defmodule GreenManTavern.Repo.Migrations.CreateUserProjects do
  use Ecto.Migration

  def change do
    create table(:user_projects) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :project_type, :string, null: false
      add :status, :string, null: false  # desire, planning, in_progress, completed, abandoned
      add :mentioned_at, :naive_datetime, null: false
      add :confidence_score, :float, null: false
      add :related_systems, :map, default: %{}  # JSONB array of system_ids
      add :notes, :text

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:user_projects, [:user_id])
    create index(:user_projects, [:user_id, :status])
  end
end
