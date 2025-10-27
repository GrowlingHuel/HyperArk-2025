defmodule GreenManTavern.Diagrams.Diagram do
  @moduledoc """
  Schema for user-created diagrams in the XyFlow-based Living Web.

  Diagrams store the complete node and edge data from XyFlow,
  allowing users to save and restore their system designs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GreenManTavern.Accounts.User

  @primary_key {:id, :id, autogenerate: true}
  schema "diagrams" do
    belongs_to :user, User
    field :name, :string
    field :description, :string
    field :nodes, :map, default: %{}
    field :edges, :map, default: %{}

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(diagram, attrs) do
    diagram
    |> cast(attrs, [:user_id, :name, :description, :nodes, :edges])
    |> validate_required([:user_id, :name])
    |> foreign_key_constraint(:user_id)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 2000)
    |> validate_map_structure(:nodes)
    |> validate_map_structure(:edges)
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

