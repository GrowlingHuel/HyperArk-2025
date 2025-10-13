defmodule GreenManTavern.Repo.Migrations.CreateUserQuests do
  use Ecto.Migration

  def change do
    create table(:user_quests) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :quest_id, references(:quests, on_delete: :delete_all), null: false
      add :status, :string, default: "available"
      add :progress_data, :jsonb, default: fragment("'{}'::jsonb")
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime

      timestamps()
    end

    create index(:user_quests, [:user_id])
    create index(:user_quests, [:quest_id])
    create index(:user_quests, [:status])
  end
end
