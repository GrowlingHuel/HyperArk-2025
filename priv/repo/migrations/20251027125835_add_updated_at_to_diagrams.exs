defmodule GreenManTavern.Repo.Migrations.AddUpdatedAtToDiagrams do
  use Ecto.Migration

  def change do
    alter table(:diagrams) do
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end
  end
end
