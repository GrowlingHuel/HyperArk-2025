defmodule GreenManTavern.Repo.Migrations.CreatePlants do
  use Ecto.Migration

  def change do
    create table(:plants) do
      add :name, :string, null: false
      add :family_id, references(:plant_families, on_delete: :restrict), null: false
      add :climate_zones, {:array, :string}, default: []
      add :description, :text

      timestamps()
    end

    create index(:plants, [:family_id])
  end
end
