defmodule GreenManTavern.Projects.UserProject do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_projects" do
    field :project_type, :string
    field :status, :string, default: "desire"
    field :mentioned_at, :naive_datetime
    field :confidence_score, :float
    field :related_systems, :map
    field :notes, :string

    belongs_to :user, GreenManTavern.Accounts.User
  end

  @doc false
  def changeset(user_project, attrs) do
    user_project
    |> cast(attrs, [
      :user_id,
      :project_type,
      :status,
      :mentioned_at,
      :confidence_score,
      :related_systems,
      :notes
    ])
    |> validate_required([:user_id, :project_type, :status, :mentioned_at, :confidence_score])
    |> validate_inclusion(:status, ["desire", "planning", "in_progress", "completed", "abandoned"])
    |> validate_number(:confidence_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end
end
