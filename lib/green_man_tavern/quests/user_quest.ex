defmodule GreenManTavern.Quests.UserQuest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_quests" do
    field :status, :string, default: "available"
    field :progress_data, :map, default: %{}
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :user, GreenManTavern.Accounts.User
    belongs_to :quest, GreenManTavern.Quests.Quest

    timestamps()
  end

  @statuses ["available", "active", "completed", "failed"]

  @doc false
  def changeset(user_quest, attrs) do
    user_quest
    |> cast(attrs, [:user_id, :quest_id, :status, :progress_data, :started_at, :completed_at])
    |> validate_required([:user_id, :quest_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:quest_id)
    |> unique_constraint([:user_id, :quest_id])
  end
end
