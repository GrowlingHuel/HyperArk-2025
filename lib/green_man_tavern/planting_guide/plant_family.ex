defmodule GreenManTavern.PlantingGuide.PlantFamily do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plant_families" do
    field :name, :string
    field :description, :string

    has_many :plants, GreenManTavern.PlantingGuide.Plant, foreign_key: :family_id

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
