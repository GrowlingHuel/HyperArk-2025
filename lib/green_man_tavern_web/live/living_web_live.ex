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
        nodes = if is_map(diagram.nodes) and diagram.nodes != %{}, do: diagram.nodes, else: %{}
        edges = if is_map(diagram.edges) and diagram.edges != %{}, do: diagram.edges, else: %{}

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

    {:noreply, socket}
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
end
