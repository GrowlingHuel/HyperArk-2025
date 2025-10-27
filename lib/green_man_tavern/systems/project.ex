defmodule GreenManTavern.Systems.Project do
  @moduledoc """
  Schema for predefined project templates in the Living Web.

  Projects are template designs that users can reference when creating
  their own systems. They include inputs, outputs, constraints, and
  skill level requirements.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "projects" do
    field :name, :string
    field :description, :string
    field :category, :string  # food, water, waste, energy
    field :inputs, :map, default: %{}
    field :outputs, :map, default: %{}
    field :constraints, {:array, :string}, default: []
    field :icon_name, :string
    field :skill_level, :string  # beginner, intermediate, advanced

    timestamps(type: :naive_datetime)
  end

  @valid_categories ~w(food water waste energy)
  @valid_skill_levels ~w(beginner intermediate advanced)

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :category, :inputs, :outputs, :constraints, :icon_name, :skill_level])
    |> validate_required([:name, :category])
    |> validate_category()
    |> validate_skill_level()
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
  end

  defp validate_category(changeset) do
    case get_field(changeset, :category) do
      nil ->
        add_error(changeset, :category, "is required")

      category when category in @valid_categories ->
        changeset

      _ ->
        add_error(changeset, :category, "must be one of: #{Enum.join(@valid_categories, ", ")}")
    end
  end

  defp validate_skill_level(changeset) do
    case get_field(changeset, :skill_level) do
      nil ->
        changeset

      skill_level when skill_level in @valid_skill_levels ->
        changeset

      _ ->
        add_error(changeset, :skill_level, "must be one of: #{Enum.join(@valid_skill_levels, ", ")}")
    end
  end
end

