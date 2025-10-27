defmodule GreenManTavern.Repo.Migrations.AddFkConstraintPrimaryCharacter do
  use Ecto.Migration

  def change do
    # Add the foreign key constraint using raw SQL to avoid timestamp issues
    execute """
            ALTER TABLE users
            ADD CONSTRAINT users_primary_character_id_fkey
            FOREIGN KEY (primary_character_id)
            REFERENCES characters(id)
            ON DELETE SET NULL
            """,
            """
            ALTER TABLE users
            DROP CONSTRAINT users_primary_character_id_fkey
            """
  end
end
