defmodule GreenManTavern.Systems.UserConnection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_connections" do
    field :status, :string, default: "potential"
    field :implemented_at, :utc_datetime_usec

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :connection, GreenManTavern.Systems.Connection
  end

  @doc false
  def changeset(user_connection, attrs) do
    user_connection
    |> cast(attrs, [:user_id, :connection_id, :status, :implemented_at])
    |> validate_required([:user_id, :connection_id])
    |> validate_inclusion(:status, ["potential", "planned", "active", "inactive"])
  end
end
