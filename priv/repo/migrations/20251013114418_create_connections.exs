defmodule GreenManTavern.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections) do
      add :from_system_id, references(:systems, on_delete: :delete_all), null: false
      add :to_system_id, references(:systems, on_delete: :delete_all), null: false
      add :flow_type, :string, null: false
      add :flow_label, :string
      add :description, :text

      # Manual timestamp fields using PostgreSQL's NOW() to avoid Elixir 1.18.2 bug
      add :inserted_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create index(:connections, [:from_system_id])
    create index(:connections, [:to_system_id])
  end
end
