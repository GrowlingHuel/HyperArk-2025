defmodule GreenManTavern.Repo.Migrations.CreateUserSystems do
  use Ecto.Migration

  def change do
    create table(:user_systems) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :system_id, references(:systems, on_delete: :delete_all), null: false
      add :status, :string, default: "planned"
      add :position_x, :integer
      add :position_y, :integer
      add :custom_notes, :text
      add :location_notes, :text
      add :implemented_at, :naive_datetime

      timestamps()
    end

    create index(:user_systems, [:user_id])
    create index(:user_systems, [:system_id])
    create index(:user_systems, [:status])
  end
end
