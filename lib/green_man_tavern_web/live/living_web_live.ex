defmodule GreenManTavernWeb.LivingWebLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Systems
  alias GreenManTavern.Diagrams

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    # Load all projects
    projects = Systems.list_projects()
    IO.puts("Loaded #{length(projects)} projects")

    # Get or create a diagram for the current user
    case Diagrams.get_or_create_diagram(current_user.id) do
      {:ok, diagram} ->
        # Initialize nodes and edges from the diagram
        raw_nodes = if is_map(diagram.nodes) and diagram.nodes != %{}, do: diagram.nodes, else: %{}
        edges = if is_map(diagram.edges) and diagram.edges != %{}, do: diagram.edges, else: %{}

        # Enrich nodes with project names
        nodes = enrich_nodes_with_project_data(raw_nodes, projects)

        socket =
          socket
          |> assign(:user_id, current_user.id)
          |> assign(:page_title, "Living Web")
          |> assign(:left_window_title, "Green Man Tavern")
          |> assign(:right_window_title, "Living Web")
          |> assign(:projects, projects)
          |> assign(:diagram, diagram)
          |> assign(:nodes, nodes)
          |> assign(:edges, edges)

        {:ok, socket}

      {:error, _changeset} ->
        {:ok,
         socket
         |> put_flash(:error, "Failed to initialize diagram")
         |> assign(:user_id, current_user.id)
         |> assign(:page_title, "Living Web")
         |> assign(:left_window_title, "Green Man Tavern")
         |> assign(:right_window_title, "Living Web")
         |> assign(:projects, [])
         |> assign(:diagram, nil)
         |> assign(:nodes, %{})
         |> assign(:edges, %{})}
    end
  end

  @impl true
  def handle_event("node_added", params, socket) do
    IO.puts("=== NODE ADDED ===")
    IO.inspect(params, label: "Params")

    case handle_node_added(params, socket) do
      {:ok, updated_socket, node_data} ->
        # Push node data back to client
        updated_socket = push_event(updated_socket, "node_added_success", node_data)

        {:noreply, updated_socket}

      {:error, reason} ->
        IO.puts("Error adding node: #{inspect(reason)}")

        # Extract temp_id if it exists
        temp_id = params["temp_id"]

        # Push error event to client
        socket =
          socket
          |> put_flash(:error, "Failed to add node: #{inspect(reason)}")
          |> push_event("node_add_error", %{temp_id: temp_id, message: "Failed to add node: #{inspect(reason)}"})

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("node_moved", params, socket) do
    IO.puts("=== NODE MOVED ===")
    IO.inspect(params, label: "Params")

    {:noreply, socket}
  end

  @impl true
  def handle_event("edge_added", params, socket) do
    IO.puts("=== EDGE ADDED ===")
    IO.inspect(params, label: "Params")

    {:noreply, socket}
  end

  defp handle_node_added(%{"project_id" => project_id_str, "x" => x_str, "y" => y_str} = params, socket) do
    # Get temp_id if present, otherwise use nil
    temp_id = Map.get(params, "temp_id")

    with {:ok, project_id} <- parse_integer(project_id_str),
         {:ok, x} <- parse_integer(x_str),
         {:ok, y} <- parse_integer(y_str),
         project when not is_nil(project) <- get_project_safe(project_id),
         node_id <- generate_node_id(),
         {:ok, diagram} <- add_node_to_diagram(socket.assigns.diagram, node_id, project.id, x, y) do
      # Update socket assigns
      updated_socket =
        socket
        |> assign(:diagram, diagram)
        |> assign(:nodes, diagram.nodes)

      # Prepare node data for the client
      node_data = %{
        temp_id: temp_id,
        id: node_id,
        project_id: project.id,
        name: project.name,
        category: project.category,
        inputs: project.inputs,
        outputs: project.outputs,
        position: %{x: x, y: y},
        icon_name: project.icon_name
      }

      {:ok, updated_socket, node_data}
    else
      nil ->
        {:error, "Project not found"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_node_added(_params, _socket) do
    {:error, "Invalid parameters"}
  end

  defp parse_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end

  defp parse_integer(integer) when is_integer(integer), do: {:ok, integer}
  defp parse_integer(_), do: {:error, :invalid_type}

  defp get_project_safe(project_id) do
    try do
      Systems.get_project!(project_id)
    rescue
      Ecto.NoResultsError -> nil
    end
  end

  defp generate_node_id do
    # Generate a unique node ID using crypto
    random_bytes = :crypto.strong_rand_bytes(8)
    node_id = "node_" <> Base.encode16(random_bytes, case: :lower)
    node_id
  end

  defp add_node_to_diagram(diagram, node_id, project_id, x, y) do
    # Create the new node map with simplified structure
    new_node = %{
      "project_id" => project_id,
      "x" => x,
      "y" => y,
      "instance_scale" => 1.0
    }

    # Add the node to the existing nodes map
    updated_nodes = Map.put(diagram.nodes, node_id, new_node)

    # Update the diagram
    case Diagrams.update_diagram(diagram, %{nodes: updated_nodes}) do
      {:ok, updated_diagram} ->
        {:ok, updated_diagram}

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "Diagram update errors")
        {:error, "Failed to update diagram"}
    end
  end

  defp enrich_nodes_with_project_data(raw_nodes, projects) do
    # Create a map of project_id -> project for quick lookup
    project_map = Map.new(projects, fn p -> {p.id, p} end)

    # Enrich each node with project data
    Enum.reduce(raw_nodes, %{}, fn {node_id, node_data}, acc ->
      project_id = node_data["project_id"]
      project = Map.get(project_map, project_id)

      if project do
        enriched_node = Map.merge(node_data, %{
          "name" => project.name,
          "category" => project.category
        })
        Map.put(acc, node_id, enriched_node)
      else
        # If project not found, keep the node but with a default name
        enriched_node = Map.merge(node_data, %{
          "name" => "Unknown Project",
          "category" => "unknown"
        })
        Map.put(acc, node_id, enriched_node)
      end
    end)
  end

end
