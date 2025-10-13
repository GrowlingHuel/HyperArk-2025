defmodule GreenManTavern.Repo.Migrations.CreateConversationHistory do
  use Ecto.Migration

  def change do
    create table(:conversation_history) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :message_type, :string, null: false
      add :message_content, :text, null: false
      add :extracted_projects, :jsonb, default: fragment("'[]'::jsonb")

      timestamps()
    end

    create index(:conversation_history, [:user_id])
    create index(:conversation_history, [:character_id])
    create index(:conversation_history, [:inserted_at])
  end
end
