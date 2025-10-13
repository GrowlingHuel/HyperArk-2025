defmodule GreenManTavern.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections) do
      add :from_system_id, references(:systems, on_delete: :delete_all), null: false
      add :to_system_id, references(:systems, on_delete: :delete_all), null: false
      add :flow_type, :string, null: false
      add :flow_label, :string
      add :description, :text

      timestamps()
    end

    create index(:connections, [:from_system_id])
    create index(:connections, [:to_system_id])
  end
end
