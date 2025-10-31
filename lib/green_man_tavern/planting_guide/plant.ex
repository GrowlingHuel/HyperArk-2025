defmodule GreenManTavern.PlantingGuide.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plants" do
    field :name, :string
    field :climate_zones, {:array, :string}, default: []
    field :description, :string

    belongs_to :family, GreenManTavern.PlantingGuide.PlantFamily
    has_many :planting_windows, GreenManTavern.PlantingGuide.PlantingWindow

    has_many :companions, GreenManTavern.PlantingGuide.Companion, foreign_key: :plant_id
    has_many :companion_of, GreenManTavern.PlantingGuide.Companion, foreign_key: :companion_plant_id

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :family_id, :climate_zones, :description])
    |> validate_required([:name, :family_id])
  end
end
