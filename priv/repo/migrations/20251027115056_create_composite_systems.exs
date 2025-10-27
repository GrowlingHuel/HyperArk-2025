defmodule GreenManTavern.Repo.Migrations.CreateCompositeSystems do
  use Ecto.Migration

  def change do
    create table(:composite_systems) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :icon_name, :string
      add :internal_node_ids, {:array, :string}, default: []
      add :internal_edge_ids, {:array, :string}, default: []
      add :external_inputs, :jsonb, default: fragment("'{}'::jsonb")
      add :external_outputs, :jsonb, default: fragment("'{}'::jsonb")
      add :is_public, :boolean, default: false
      add :parent_diagram_id, references(:diagrams, on_delete: :delete_all)

      timestamps(type: :naive_datetime, updated_at: false)
    end

    create index(:composite_systems, [:user_id])
    create index(:composite_systems, [:parent_diagram_id])
    create index(:composite_systems, [:is_public])
    create index(:composite_systems, [:name])
    create index(:composite_systems, [:inserted_at])
  end
end
