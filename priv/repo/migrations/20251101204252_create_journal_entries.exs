defmodule GreenManTavern.Repo.Migrations.CreateJournalEntries do
  use Ecto.Migration

  def change do
    create table(:journal_entries) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :entry_date, :string, null: false  # e.g. "3rd of Last Seed"
      add :day_number, :integer, null: false  # e.g. 42
      add :title, :string
      add :body, :text, null: false
      add :source_type, :string, null: false  # "character_conversation", "quest_completion", "system_action", "manual_entry"
      add :source_id, :integer  # nullable - references character_id, quest_id, system_id depending on source_type

      timestamps()
    end

    create index(:journal_entries, [:user_id])
    create index(:journal_entries, [:day_number])
    create index(:journal_entries, [:user_id, :day_number])
    create index(:journal_entries, [:source_type])
  end
end
