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

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:user_systems, [:user_id])
    create index(:user_systems, [:system_id])
    create index(:user_systems, [:status])
  end
end
