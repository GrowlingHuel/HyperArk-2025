defmodule GreenManTavern.PlantingGuide.Companion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companions" do
    field :relation, :string
    field :notes, :string

    belongs_to :plant, GreenManTavern.PlantingGuide.Plant
    belongs_to :companion_plant, GreenManTavern.PlantingGuide.Plant, foreign_key: :companion_plant_id

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:plant_id, :companion_plant_id, :relation, :notes])
    |> validate_required([:plant_id, :companion_plant_id, :relation])
    |> validate_inclusion(:relation, ["good", "bad"])
    |> check_constraint(:companion_plant_id, name: :no_self_companion)
  end
end
