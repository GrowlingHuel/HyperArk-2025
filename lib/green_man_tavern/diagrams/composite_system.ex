defmodule GreenManTavern.Diagrams.CompositeSystem do
  @moduledoc """
  Schema for composite systems - saved reusable system designs.

  Composite systems are collections of nodes and edges that can be
  saved as reusable components. They can reference parent diagrams
  and define external inputs/outputs for integration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GreenManTavern.Accounts.User
  alias GreenManTavern.Diagrams.Diagram

  @primary_key {:id, :id, autogenerate: true}
  schema "composite_systems" do
    belongs_to :user, User
    field :name, :string
    field :description, :string
    field :icon_name, :string
    field :internal_node_ids, {:array, :string}, default: []
    field :internal_edge_ids, {:array, :string}, default: []
    field :external_inputs, :map, default: %{}
    field :external_outputs, :map, default: %{}
    field :is_public, :boolean, default: false
    belongs_to :parent_diagram, Diagram, foreign_key: :parent_diagram_id

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(composite_system, attrs) do
    composite_system
    |> cast(attrs, [:user_id, :name, :description, :icon_name, :internal_node_ids, :internal_edge_ids, :external_inputs, :external_outputs, :is_public, :parent_diagram_id])
    |> validate_required([:user_id, :name])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:parent_diagram_id)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 2000)
    |> validate_map_structure(:external_inputs)
    |> validate_map_structure(:external_outputs)
  end

  defp validate_map_structure(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value when is_map(value) ->
        changeset

      _ ->
        add_error(changeset, field, "must be a map/JSONB object")
    end
  end
end
