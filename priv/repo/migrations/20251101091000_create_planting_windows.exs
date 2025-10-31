defmodule GreenManTavern.Repo.Migrations.CreatePlantingWindows do
  use Ecto.Migration

  def change do
    create table(:planting_windows) do
      add :plant_id, references(:plants, on_delete: :delete_all), null: false
      add :month, :integer, null: false
      add :hemisphere, :string, null: false
      add :action, :string, null: false

      timestamps()
    end

    create index(:planting_windows, [:plant_id])
    create index(:planting_windows, [:month])
    create index(:planting_windows, [:hemisphere])
    create index(:planting_windows, [:plant_id, :month, :hemisphere])

    # Basic constraints
    create constraint(:planting_windows, :month_between_1_12, check: "month >= 1 AND month <= 12")
    create constraint(:planting_windows, :hemisphere_valid, check: "hemisphere IN ('N','S')")
  end
end
