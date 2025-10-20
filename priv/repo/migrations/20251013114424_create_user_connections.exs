defmodule GreenManTavern.Repo.Migrations.CreateUserConnections do
  use Ecto.Migration

  def change do
    create table(:user_connections) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :connection_id, references(:connections, on_delete: :delete_all), null: false
      add :status, :string, default: "potential"
      add :implemented_at, :naive_datetime

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:user_connections, [:user_id])
    create index(:user_connections, [:connection_id])
  end
end
