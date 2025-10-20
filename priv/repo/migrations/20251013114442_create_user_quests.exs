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

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:user_quests, [:user_id])
    create index(:user_quests, [:quest_id])
    create index(:user_quests, [:status])
  end
end
