defmodule GreenManTavern.Diagrams do
  @moduledoc """
  The Diagrams context for managing user diagrams.
  """

  import Ecto.Query, warn: false
  alias GreenManTavern.Repo
  alias GreenManTavern.Diagrams.Diagram
  alias GreenManTavern.Diagrams.CompositeSystem

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

  # ==== Composite Systems ====

  @doc """
  Returns the list of composite systems for a user.
  """
  def list_composite_systems(user_id) do
    from(cs in CompositeSystem, where: cs.user_id == ^user_id, order_by: [desc: cs.inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single composite system.
  """
  def get_composite_system!(id), do: Repo.get!(CompositeSystem, id)

  @doc """
  Creates a composite system.
  """
  def create_composite_system(attrs \\ %{}) do
    %CompositeSystem{}
    |> CompositeSystem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a composite system.
  """
  def update_composite_system(%CompositeSystem{} = composite_system, attrs) do
    composite_system
    |> CompositeSystem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a composite system.
  """
  def delete_composite_system(%CompositeSystem{} = composite_system) do
    Repo.delete(composite_system)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking composite system changes.
  """
  def change_composite_system(%CompositeSystem{} = composite_system, attrs \\ %{}) do
    CompositeSystem.changeset(composite_system, attrs)
  end

  @doc """
  Infers external inputs and outputs for a composite system based on internal nodes and edges.

  Logic:
  - Collects all inputs/outputs from internal nodes (from their projects)
  - Finds nodes with edges TO internal nodes (external sources) -> these become inputs
  - Finds nodes with edges FROM internal nodes (external targets) -> these become outputs
  - Merges and deduplicates
  """
  def infer_external_io(internal_node_ids, diagram_nodes, diagram_edges, projects) do
    project_map = Map.new(projects || [], fn p -> {p.id, p} end)

    # Get all internal nodes
    internal_nodes =
      internal_node_ids
      |> Enum.map(fn node_id -> {node_id, Map.get(diagram_nodes || %{}, node_id)} end)
      |> Enum.filter(fn {_id, data} -> not is_nil(data) end)
      |> Map.new()

    # Collect all inputs/outputs from internal nodes' projects
    {internal_inputs, internal_outputs} =
      internal_nodes
      |> Enum.reduce({%{}, %{}}, fn {_node_id, node_data}, {acc_inputs, acc_outputs} ->
        project_id = case node_data["project_id"] do
          id when is_integer(id) -> id
          id when is_binary(id) -> String.to_integer(id)
          _ -> nil
        end

        project = Map.get(project_map, project_id)
        if project do
          # Collect inputs/outputs from project
          project_inputs = project.inputs || %{}
          project_outputs = project.outputs || %{}

          # Merge into accumulated inputs/outputs
          {Map.merge(acc_inputs, project_inputs), Map.merge(acc_outputs, project_outputs)}
        else
          {acc_inputs, acc_outputs}
        end
      end)

    # Find edges connecting to/from internal nodes
    edges = diagram_edges || %{}
    internal_node_set = MapSet.new(internal_node_ids)

    # External sources (nodes with edges TO internal nodes)
    external_inputs =
      edges
      |> Enum.reduce(%{}, fn {_edge_id, edge_data}, acc ->
        source_id = edge_data["source_id"]
        target_id = edge_data["target_id"]

        # If source is external and target is internal, this is an input
        if not MapSet.member?(internal_node_set, source_id) and
           MapSet.member?(internal_node_set, target_id) do
          source_node = Map.get(diagram_nodes || %{}, source_id)
          if source_node do
            project_id = case source_node["project_id"] do
              id when is_integer(id) -> id
              id when is_binary(id) -> String.to_integer(id)
              _ -> nil
            end

            project = Map.get(project_map, project_id)
            if project do
              # Add outputs from external source as inputs to composite
              outputs = project.outputs || %{}
              Map.merge(acc, outputs)
            else
              acc
            end
          else
            acc
          end
        else
          acc
        end
      end)

    # External targets (nodes with edges FROM internal nodes)
    external_outputs =
      edges
      |> Enum.reduce(%{}, fn {_edge_id, edge_data}, acc ->
        source_id = edge_data["source_id"]
        target_id = edge_data["target_id"]

        # If source is internal and target is external, this is an output
        if MapSet.member?(internal_node_set, source_id) and
           not MapSet.member?(internal_node_set, target_id) do
          source_node = Map.get(diagram_nodes || %{}, source_id)
          if source_node do
            project_id = case source_node["project_id"] do
              id when is_integer(id) -> id
              id when is_binary(id) -> String.to_integer(id)
              _ -> nil
            end

            project = Map.get(project_map, project_id)
            if project do
              # Add outputs from internal source as outputs of composite
              outputs = project.outputs || %{}
              Map.merge(acc, outputs)
            else
              acc
            end
          else
            acc
          end
        else
          acc
        end
      end)

    # Merge internal and external, deduplicate
    final_inputs = Map.merge(internal_inputs, external_inputs)
    final_outputs = Map.merge(internal_outputs, external_outputs)

    {final_inputs, final_outputs}
  end
end
