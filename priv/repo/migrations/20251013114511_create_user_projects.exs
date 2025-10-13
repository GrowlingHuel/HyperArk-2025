defmodule GreenManTavern.Repo.Migrations.CreateUserProjects do
  use Ecto.Migration

  def change do
    create table(:user_projects) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :project_type, :string, null: false
      add :status, :string, default: "desire"
      add :mentioned_at, :naive_datetime, null: false
      add :confidence_score, :float, default: 0.5
      add :related_systems, :jsonb, default: fragment("'[]'::jsonb")
      add :notes, :text

      timestamps()
    end

    create index(:user_projects, [:user_id])
    create index(:user_projects, [:status])
  end
end
