defmodule GreenManTavern.Repo.Migrations.CreateUserConnections do
  use Ecto.Migration

  def change do
    create table(:user_connections) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :connection_id, references(:connections, on_delete: :delete_all), null: false
      add :status, :string, default: "potential"
      add :implemented_at, :naive_datetime

      timestamps()
    end

    create index(:user_connections, [:user_id])
    create index(:user_connections, [:connection_id])
  end
end
