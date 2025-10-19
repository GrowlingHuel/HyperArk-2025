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

      timestamps()
    end

    create index(:user_projects, [:user_id])
    create index(:user_projects, [:user_id, :status])
  end
end
