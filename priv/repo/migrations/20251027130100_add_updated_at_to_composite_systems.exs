defmodule GreenManTavern.Repo.Migrations.AddUpdatedAtToCompositeSystems do
  use Ecto.Migration

  def change do
    alter table(:composite_systems) do
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end
  end
end
