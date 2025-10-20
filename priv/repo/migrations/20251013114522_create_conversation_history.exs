defmodule GreenManTavern.Repo.Migrations.CreateConversationHistory do
  use Ecto.Migration

  def change do
    create table(:conversation_history) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :message_type, :string, null: false
      add :message_content, :text, null: false
      add :extracted_projects, :jsonb, default: fragment("'[]'::jsonb")

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:conversation_history, [:user_id])
    create index(:conversation_history, [:character_id])
    create index(:conversation_history, [:inserted_at])
  end
end
