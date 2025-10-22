defmodule GreenManTavern.Systems.System do
  use Ecto.Schema
  import Ecto.Changeset

  schema "systems" do
    field :name, :string
    field :system_type, :string
    field :category, :string
    field :description, :string
    field :requirements, :string
    field :default_inputs, {:array, :string}
    field :default_outputs, {:array, :string}
    field :icon_name, :string
    field :space_required, :string
    field :skill_level, :string
    field :color_scheme, :string

    has_many :user_systems, GreenManTavern.Systems.UserSystem
    has_many :connections_from, GreenManTavern.Systems.Connection, foreign_key: :from_system_id
    has_many :connections_to, GreenManTavern.Systems.Connection, foreign_key: :to_system_id
  end

  @doc false
  def changeset(system, attrs) do
    system
    |> cast(attrs, [
      :name,
      :system_type,
      :category,
      :description,
      :requirements,
      :default_inputs,
      :default_outputs,
      :icon_name,
      :space_required,
      :skill_level,
      :color_scheme
    ])
    |> validate_required([:name, :system_type, :category])
    |> validate_inclusion(:system_type, ["resource", "process", "storage"])
    |> validate_inclusion(:category, ["food", "water", "waste", "energy"])
    |> validate_inclusion(:skill_level, ["beginner", "intermediate", "advanced"])
  end
end
