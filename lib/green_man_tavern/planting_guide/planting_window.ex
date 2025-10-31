defmodule GreenManTavern.PlantingGuide.PlantingWindow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "planting_windows" do
    field :month, :integer
    field :hemisphere, :string
    field :action, :string

    belongs_to :plant, GreenManTavern.PlantingGuide.Plant

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:plant_id, :month, :hemisphere, :action])
    |> validate_required([:plant_id, :month, :hemisphere, :action])
    |> validate_inclusion(:month, 1..12)
    |> validate_inclusion(:hemisphere, ["N", "S"])
  end
end
