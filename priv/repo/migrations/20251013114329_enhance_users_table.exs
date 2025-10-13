defmodule GreenManTavern.Repo.Migrations.EnhanceUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_data, :jsonb, default: fragment("'{}'::jsonb")
      add :primary_character_id, references(:characters, on_delete: :nilify_all)
      add :xp, :integer, default: 0
      add :level, :integer, default: 1
    end

    create index(:users, [:primary_character_id])
  end
end
