defmodule GreenManTavern.Systems.UserSystem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_systems" do
    field :status, :string, default: "planned"
    field :position_x, :integer
    field :position_y, :integer
    field :custom_notes, :string
    field :location_notes, :string
    field :implemented_at, :utc_datetime_usec

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :system, GreenManTavern.Systems.System

    timestamps()
  end

  @doc false
  def changeset(user_system, attrs) do
    user_system
    |> cast(attrs, [
      :user_id,
      :system_id,
      :status,
      :position_x,
      :position_y,
      :custom_notes,
      :location_notes,
      :implemented_at
    ])
    |> validate_required([:user_id, :system_id])
    |> validate_inclusion(:status, ["planned", "active", "inactive"])
  end
end
