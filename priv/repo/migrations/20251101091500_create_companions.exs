defmodule GreenManTavern.Repo.Migrations.CreateCompanions do
  use Ecto.Migration

  def change do
    create table(:companions) do
      add :plant_id, references(:plants, on_delete: :delete_all), null: false
      add :companion_plant_id, references(:plants, on_delete: :delete_all), null: false
      add :relation, :string, null: false
      add :notes, :text

      timestamps()
    end

    create index(:companions, [:plant_id])
    create index(:companions, [:companion_plant_id])
    create index(:companions, [:plant_id, :companion_plant_id])

    # Prevent self-referencing companion links
    create constraint(:companions, :no_self_companion, check: "plant_id <> companion_plant_id")

    # Optional: relation domain
    create constraint(:companions, :relation_valid, check: "relation IN ('good','bad')")
  end
end
