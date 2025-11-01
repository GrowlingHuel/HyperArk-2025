defmodule GreenManTavern.Diagrams.Suggestions do
  @moduledoc """
  Provides intelligent suggestions for system improvements and connections.

  Uses a combination of:
  - Rule-based logic (checking missing inputs, common patterns)
  - Database patterns (other users' composite systems)
  - AI analysis (future integration)
  """


  @doc """
  Generate suggestions for the current diagram state.

  Returns a list of suggestion maps with:
  - type: :connection, :addition, :improvement
  - description: Human-readable description
  - action: Actionable data for applying the suggestion
  - priority: :high, :medium, :low
  """
  def generate_suggestions(nodes, edges, projects) do
    suggestions = []

    all_suggestions =
      suggestions
      ++ check_missing_inputs(nodes, edges, projects)
      ++ check_common_patterns(nodes, edges, projects)
      ++ check_system_completeness(nodes, edges, projects)

    # Sort by priority
    all_suggestions
    |> Enum.sort_by(fn s -> priority_score(s.priority) end, :desc)
  end

  # Check for nodes that have inputs that aren't satisfied by any connections
  defp check_missing_inputs(nodes, edges, projects) do
    node_map = nodes || %{}
    edges_map = edges || %{}
    project_map = Map.new(projects || [], fn p -> {p.id, p} end)

    suggestions = []

    node_map
    |> Enum.reduce(suggestions, fn {node_id, node_data}, acc ->
      project_id = case node_data["project_id"] do
        id when is_integer(id) -> id
        id when is_binary(id) -> String.to_integer(id)
        _ -> nil
      end

      project = Map.get(project_map, project_id)
      if project do
        # Get required inputs
        required_inputs = project.inputs || %{}

        # Check if inputs are satisfied by incoming edges
        incoming_edges =
          edges_map
          |> Enum.filter(fn {_edge_id, edge_data} ->
            edge_data["target_id"] == node_id
          end)

        # For each required input, check if there's a source providing it
        input_suggestions =
          required_inputs
          |> Enum.map(fn {input_key, input_value} ->
            # Find nodes that could provide this input (have matching output)
            potential_sources =
              node_map
              |> Enum.filter(fn {source_id, source_data} ->
                source_id != node_id &&
                  has_matching_output?(source_data, input_key, input_value, project_map)
              end)
              |> Enum.map(fn {id, _} -> id end)

            if length(potential_sources) > 0 and length(incoming_edges) == 0 do
              source_id = List.first(potential_sources)
              %{
                type: :connection,
                description: "Connect '#{get_node_name(source_id, node_map, project_map)}' to '#{get_node_name(node_id, node_map, project_map)}' to provide #{input_key}",
                action: %{
                  source_id: source_id,
                  target_id: node_id,
                  reason: "Missing input: #{input_key}"
                },
                priority: :high
              }
            else
              nil
            end
          end)
          |> Enum.filter(& &1)

        acc ++ input_suggestions
      else
        acc
      end
    end)
  end

  # Check for common permaculture patterns
  defp check_common_patterns(nodes, _edges, projects) do
    node_map = nodes || %{}
    project_map = Map.new(projects || [], fn p -> {p.id, p} end)

    suggestions = []

    # Common pattern: Compost needs organic waste
    compost_nodes =
      node_map
      |> Enum.filter(fn {_id, node_data} ->
        project_id = case node_data["project_id"] do
          id when is_integer(id) -> id
          id when is_binary(id) -> String.to_integer(id)
          _ -> nil
        end
        project = Map.get(project_map, project_id)
        project && String.contains?(String.downcase(project.name || ""), "compost")
      end)
      |> Enum.map(fn {id, _} -> id end)

    waste_nodes =
      node_map
      |> Enum.filter(fn {_id, node_data} ->
        project_id = case node_data["project_id"] do
          id when is_integer(id) -> id
          id when is_binary(id) -> String.to_integer(id)
          _ -> nil
        end
        project = Map.get(project_map, project_id)
        project && project.category == "waste"
      end)
      |> Enum.map(fn {id, _} -> id end)

    # Suggest connecting waste to compost
    compost_suggestions =
      compost_nodes
      |> Enum.flat_map(fn compost_id ->
        waste_nodes
        |> Enum.map(fn waste_id ->
          %{
            type: :connection,
            description: "Connect waste source to compost system for organic recycling",
            action: %{
              source_id: waste_id,
              target_id: compost_id,
              reason: "Common pattern: waste → compost"
            },
            priority: :medium
          }
        end)
      end)

    suggestions = suggestions ++ compost_suggestions

    # Add more common patterns here (water → plants, energy → systems, etc.)

    suggestions
  end

  # Check if system is complete (all inputs satisfied, outputs utilized)
  defp check_system_completeness(nodes, edges, projects) do
    node_map = nodes || %{}
    edges_map = edges || %{}
    project_map = Map.new(projects || [], fn p -> {p.id, p} end)

    # Check for nodes with many outputs but few connections
    nodes_with_outputs =
      node_map
      |> Enum.map(fn {node_id, node_data} ->
        project_id = case node_data["project_id"] do
          id when is_integer(id) -> id
          id when is_binary(id) -> String.to_integer(id)
          _ -> nil
        end
        project = Map.get(project_map, project_id)
        output_count = if project, do: map_size(project.outputs || %{}), else: 0

        outgoing_edges =
          edges_map
          |> Enum.count(fn {_edge_id, edge_data} ->
            edge_data["source_id"] == node_id
          end)

        {node_id, output_count, outgoing_edges}
      end)

    underutilized =
      nodes_with_outputs
      |> Enum.filter(fn {_id, output_count, outgoing_edges} ->
        output_count > 2 && outgoing_edges < output_count / 2
      end)

    if length(underutilized) > 0 do
      [%{
        type: :improvement,
        description: "Some systems have unused outputs - consider connecting them to other systems",
        action: %{type: :review_connections},
        priority: :low
      }]
    else
      []
    end
  end

  # Helper functions
  defp has_matching_output?(source_data, input_key, _input_value, project_map) do
    project_id = case source_data["project_id"] do
      id when is_integer(id) -> id
      id when is_binary(id) -> String.to_integer(id)
      _ -> nil
    end

    project = Map.get(project_map, project_id)
    if project do
      outputs = project.outputs || %{}
      Map.has_key?(outputs, input_key)
    else
      false
    end
  end

  defp get_node_name(node_id, node_map, project_map) do
    node_data = Map.get(node_map, node_id)
    if node_data do
      custom_name = node_data["custom_name"]
      if custom_name do
        custom_name
      else
        project_id = case node_data["project_id"] do
          id when is_integer(id) -> id
          id when is_binary(id) -> String.to_integer(id)
          _ -> nil
        end
        project = Map.get(project_map, project_id)
        if project, do: project.name, else: "Unknown"
      end
    else
      "Unknown"
    end
  end

  defp priority_score(priority) when is_atom(priority) do
    case priority do
      :high -> 3
      :medium -> 2
      :low -> 1
      _ -> 0
    end
  end
  defp priority_score(_), do: 0
end
