defmodule GreenManTavern.Repo.Migrations.CreateUserCharacters do
  use Ecto.Migration

  def change do
    create table(:user_characters) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :trust_level, :integer, default: 0
      add :first_interaction_at, :naive_datetime
      add :last_interaction_at, :naive_datetime
      add :interaction_count, :integer, default: 0
      add :is_trusted, :boolean, default: false

      timestamps()
    end

    create unique_index(:user_characters, [:user_id, :character_id])
    create index(:user_characters, [:user_id])
    create index(:user_characters, [:character_id])
  end
end
