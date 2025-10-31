defmodule GreenManTavern.Repo.Migrations.CreatePlantFamilies do
  use Ecto.Migration

  def change do
    create table(:plant_families) do
      add :name, :string, null: false
      add :description, :text

      timestamps()
    end

    create unique_index(:plant_families, [:name])
  end
end
