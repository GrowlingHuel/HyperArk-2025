defmodule GreenManTavern.Diagrams do
  @moduledoc """
  The Diagrams context for managing user diagrams.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Diagrams.Diagram

  @doc """
  Returns the list of diagrams for a user.
  """
  def list_diagrams(user_id) do
    from(d in Diagram, where: d.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single diagram.
  """
  def get_diagram!(id), do: Repo.get!(Diagram, id)

  @doc """
  Gets or creates a diagram for a user.
  Creates a default diagram if one doesn't exist.
  """
  def get_or_create_diagram(user_id) do
    case from(d in Diagram, where: d.user_id == ^user_id, limit: 1) |> Repo.one() do
      nil ->
        # Create a default diagram for the user
        %Diagram{}
        |> Diagram.changeset(%{
          user_id: user_id,
          name: "My Living Web",
          description: "My permaculture system diagram",
          nodes: %{},
          edges: %{}
        })
        |> Repo.insert()
        |> case do
          {:ok, diagram} -> {:ok, diagram}
          {:error, changeset} -> {:error, changeset}
        end

      diagram ->
        {:ok, diagram}
    end
  end

  @doc """
  Creates a diagram.
  """
  def create_diagram(attrs \\ %{}) do
    %Diagram{}
    |> Diagram.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a diagram.
  """
  def update_diagram(%Diagram{} = diagram, attrs) do
    diagram
    |> Diagram.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a diagram.
  """
  def delete_diagram(%Diagram{} = diagram) do
    Repo.delete(diagram)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking diagram changes.
  """
  def change_diagram(%Diagram{} = diagram, attrs \\ %{}) do
    Diagram.changeset(diagram, attrs)
  end
end
