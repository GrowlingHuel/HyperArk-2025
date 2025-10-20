defmodule GreenManTavern.Repo.Migrations.AddFkConstraintPrimaryCharacter do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :primary_character_id, references(:characters, on_delete: :nilify_all)
    end
  end
end
