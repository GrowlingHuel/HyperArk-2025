defmodule GreenManTavern.Systems.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "connections" do
    field :flow_type, :string
    field :flow_label, :string
    field :description, :string

    belongs_to :from_system, GreenManTavern.Systems.System
    belongs_to :to_system, GreenManTavern.Systems.System
    has_many :user_connections, GreenManTavern.Systems.UserConnection

    timestamps()
  end

  @doc false
  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:from_system_id, :to_system_id, :flow_type, :flow_label, :description])
    |> validate_required([:from_system_id, :to_system_id, :flow_type])
    |> validate_inclusion(:flow_type, ["active", "potential"])
  end
end
