defmodule GreenManTavernWeb.LivingWebLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Systems
  alias GreenManTavern.Characters


  @impl true
  def mount(_params, _session, socket) do
    # User is guaranteed to be authenticated due to router pipeline
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(:user_id, current_user.id)
      |> assign(:page_title, "Living Web")
      |> assign(:left_window_title, "Green Man Tavern")
      |> assign(:right_window_title, "Living Web")
      |> assign(:character, nil)
      |> assign(:chat_messages, [])
      |> assign(:current_message, "")
      |> assign(:selected_system, nil)
      |> assign(:selected_node_id, nil)
      |> assign(:show_connections, true)
      |> assign(:show_potential, true)
      |> assign(:systems_by_category, [])
      |> assign(:user_systems, [])
      |> assign(:user_connections, [])
      |> assign(:user_space_type, get_user_space_type(current_user))
      |> assign(:icon_map, build_icon_map())
      |> load_systems_data(current_user.id)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Handle character parameter from URL
    character = case params["character"] do
      nil -> nil
      character_id ->
        try do
          Characters.get_character!(String.to_integer(character_id))
        rescue
          _ -> nil
        end
    end

    socket = if character do
      socket
      |> assign(:character, character)
      |> assign(:left_window_title, "Tavern - #{character.name}")
    else
      socket
      |> assign(:character, nil)
      |> assign(:left_window_title, "Green Man Tavern")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    IO.inspect(character_id, label: "LIVING WEB LIVE - CHARACTER SELECTION - ID")

    character = Characters.get_character!(character_id)
    IO.inspect(character.name, label: "LIVING WEB LIVE - CHARACTER SELECTION - NAME")

    socket = socket
      |> assign(:character, character)
      |> assign(:left_window_title, "Tavern - #{character.name}")
      |> assign(:chat_messages, [])
      |> assign(:current_message, "")

    IO.inspect(socket.assigns.character, label: "LIVING WEB LIVE - SOCKET ASSIGNS AFTER SELECTION")
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{}, socket) do
    message = socket.assigns.current_message || ""

    if String.trim(message) == "" do
      {:noreply, socket}
    else
      IO.puts("=== SEND MESSAGE TRIGGERED (Button) ===")
      IO.puts("Sending async message: #{message}")
      send_message(socket, message)
    end
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :current_message, message)}
  end

  @impl true
  def handle_event("toggle_potential", _params, socket) do
    {:noreply, assign(socket, :show_potential, !socket.assigns.show_potential)}
  end

  @impl true
  def handle_event("select_node", %{"id" => system_id}, socket) do
    {:noreply, assign(socket, :selected_node_id, system_id)}
  end

  @impl true
  def handle_event("deselect_node", _params, socket) do
    {:noreply, assign(socket, :selected_node_id, nil)}
  end

  @impl true
  def handle_event("select_system", %{"system_id" => system_id}, socket) do
    system = Systems.get_system!(system_id)
    {:noreply, assign(socket, :selected_system, system)}
  end

  @impl true
  def handle_event("deselect_system", _params, socket) do
    {:noreply, assign(socket, :selected_system, nil)}
  end

  @impl true
  def handle_event("toggle_connections", _params, socket) do
    {:noreply, assign(socket, :show_connections, !socket.assigns.show_connections)}
  end

  @impl true
  def handle_event("add_system", %{"system_id" => system_id}, socket) do
    user_id = socket.assigns.user_id
    system = Systems.get_system!(system_id)

    case Systems.create_user_system(%{
           user_id: user_id,
           system_id: system.id,
           status: "planned",
           position_x: 100,
           position_y: 100
         }) do
      {:ok, _user_system} ->
        socket =
          socket
          |> put_flash(:info, "Added #{system.name} to your Living Web")
          |> load_user_systems(user_id)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add system")}
    end
  end


  defp find_system(user_systems, system_id) do
    Enum.find(user_systems, fn us -> us.system.id == system_id end)
  end

  defp render_connection(connection, from_system, to_system, show_potential?) do
    # Skip potential connections if show_potential is false
    if connection.status == "potential" and not show_potential? do
      nil
    else
      # Calculate positions
      start_x = from_system.position_x + 60
      start_y = from_system.position_y + 40
      end_x = to_system.position_x + 60
      end_y = to_system.position_y + 40
      mid_x = (start_x + end_x) / 2
      mid_y = (start_y + end_y) / 2 - 50

      # Determine styling based on status
      {stroke_color, marker_id, label_color} = case connection.status do
        "active" -> {"#22c55e", "arrow-active", "#15803d"}
        "potential" -> {"#f97316", "arrow-potential", "#c2410c"}
        _ -> {"#6b7280", "arrow-active", "#4b5563"}
      end

      stroke_dasharray = if connection.status == "potential", do: "8,4", else: ""
      opacity = if connection.status == "potential", do: "0.7", else: "1"

      assigns = %{
        start_x: start_x,
        start_y: start_y,
        end_x: end_x,
        end_y: end_y,
        mid_x: mid_x,
        mid_y: mid_y,
        stroke_color: stroke_color,
        marker_id: marker_id,
        label_color: label_color,
        stroke_dasharray: stroke_dasharray,
        opacity: opacity,
        flow_label: connection.connection.flow_label
      }

      ~H"""
      <g class="connection-group">
        <!-- Connection path -->
        <path
          d={"M #{@start_x} #{@start_y} Q #{@mid_x} #{@mid_y} #{@end_x} #{@end_y}"}
          fill="none"
          stroke={@stroke_color}
          stroke-width="3"
          stroke-dasharray={@stroke_dasharray}
          marker-end={"url(##{@marker_id})"}
          opacity={@opacity}
          class="connection-path"
        />

        <!-- Flow label -->
        <text
          x={@mid_x}
          y={@mid_y - 40}
          text-anchor="middle"
          font-size="12"
          font-weight="500"
          fill={@label_color}
          class="flow-label"
        >
          {@flow_label}
        </text>
      </g>
      """
    end
  end

  defp render_node(user_system, selected?) do
    system = user_system.system
    x = user_system.position_x
    y = user_system.position_y

    # Category colors
    {fill_color, border_color} = get_category_colors(system.category, system.system_type)

    # Border width based on selection
    border_width = if selected?, do: 4, else: 2

    # Icon component
    icon_name = get_icon_component(system.icon_name)

    assigns = %{icon_name: icon_name, system: system, x: x, y: y, fill_color: fill_color, border_color: border_color, border_width: border_width}

    ~H"""
    <g class="system-node" phx-click="select_node" phx-value-id={@system.id} phx-click-away="deselect_node">
      <!-- Main rectangle -->
      <rect
        x={@x - 60}
        y={@y - 40}
        width="120"
        height="80"
        rx="8"
        fill={@fill_color}
        stroke={@border_color}
        stroke-width={@border_width}
        class="system-rect"
      />

      <!-- Process badge -->
      <%= if @system.system_type == "process" do %>
        <circle
          cx={@x}
          cy={@y - 32}
          r="8"
          fill="#8B5CF6"
          stroke="#000000"
          stroke-width="1"
        />
      <% end %>

      <!-- Content area -->
      <foreignObject x={@x - 50} y={@y - 30} width="100" height="60">
        <div class="node-content">
          <!-- Icon -->
          <div class="node-icon">
            <.icon name={@icon_name} class="w-8 h-8" />
          </div>

          <!-- System name -->
          <div class="node-name">
            {@system.name}
          </div>

          <!-- Requirements for process nodes -->
          <%= if @system.system_type == "process" do %>
            <div class="node-requirements">
              {@system.requirements}
            </div>
          <% end %>
        </div>
      </foreignObject>
    </g>
    """
  end

  defp get_category_colors(category, system_type) do
    case {category, system_type} do
      {"food", _} -> {"#dcfce7", "#16a34a"}  # light green, dark green
      {_, "process"} -> {"#fef3c7", "#d97706"}  # light amber, dark amber
      {_, "storage"} -> {"#ffedd5", "#ea580c"}  # light orange, dark orange
      {"water", _} -> {"#dbeafe", "#2563eb"}  # light blue, dark blue
      {"waste", _} -> {"#dbeafe", "#2563eb"}  # light blue, dark blue
      {"energy", _} -> {"#fef9c3", "#ca8a04"}  # light yellow, dark yellow
      _ -> {"#f3f4f6", "#6b7280"}  # light grey, dark grey
    end
  end

  defp get_icon_component(icon_name) do
    case icon_name do
      "Leaf" -> "hero-leaf"
      "Sun" -> "hero-sun"
      "Container" -> "hero-archive-box"
      "Droplets" -> "hero-droplet"
      "Circle" -> "hero-circle"
      "Square" -> "hero-square"
      "TreeDeciduous" -> "hero-tree"
      "TreePine" -> "hero-tree"
      "Cherry" -> "hero-cake"
      "Sprout" -> "hero-sparkles"
      "Fish" -> "hero-fish"
      "Bug" -> "hero-bug"
      "Zap" -> "hero-bolt"
      "Archive" -> "hero-archive-box"
      "Snowflake" -> "hero-snowflake"
      "Wind" -> "hero-wind"
      "Flame" -> "hero-fire"
      "ArrowUp" -> "hero-arrow-up"
      "ArrowDown" -> "hero-arrow-down"
      _ -> "hero-cube"  # default
    end
  end

  defp build_icon_map do
    %{
      "Leaf" => "hero-leaf",
      "Sun" => "hero-sun",
      "Container" => "hero-archive-box",
      "Droplets" => "hero-droplet",
      "Circle" => "hero-circle",
      "Square" => "hero-square",
      "TreeDeciduous" => "hero-tree",
      "TreePine" => "hero-tree",
      "Cherry" => "hero-cake",
      "Sprout" => "hero-sparkles",
      "Fish" => "hero-fish",
      "Bug" => "hero-bug",
      "Zap" => "hero-bolt",
      "Archive" => "hero-archive-box",
      "Snowflake" => "hero-snowflake",
      "Wind" => "hero-wind",
      "Flame" => "hero-fire",
      "ArrowUp" => "hero-arrow-up",
      "ArrowDown" => "hero-arrow-down"
    }
  end

  defp load_systems_data(socket, user_id) do
    try do
      # Load all systems
      all_systems = Systems.list_systems()

      # Filter by user's space type
      user_space_type = socket.assigns.user_space_type
      filtered_systems = Systems.filter_systems_by_space(all_systems, user_space_type)

      # Group by category
      systems_by_category = Systems.group_systems_by_category(filtered_systems)

      # Load user's active systems
      user_systems = Systems.list_active_user_systems(user_id)

      # Load user's connections
      user_connections = Systems.get_user_connections(user_id)

      socket
      |> assign(:systems_by_category, systems_by_category)
      |> assign(:user_systems, user_systems)
      |> assign(:user_connections, user_connections)
    rescue
      error ->
        socket
        |> put_flash(:error, "Failed to load systems data: #{inspect(error)}")
        |> assign(:systems_by_category, [])
        |> assign(:user_systems, [])
        |> assign(:user_connections, [])
    end
  end

  defp load_user_systems(socket, user_id) do
    try do
      user_systems = Systems.list_active_user_systems(user_id)
      assign(socket, :user_systems, user_systems)
    rescue
      error ->
        socket
        |> put_flash(:error, "Failed to load user systems: #{inspect(error)}")
        |> assign(:user_systems, [])
    end
  end

  defp get_user_space_type(user) do
    case user.profile_data do
      %{"space_type" => space_type} when is_binary(space_type) -> space_type
      _ -> "outdoor"
    end
  end

  defp send_message(socket, message) when message in [nil, ""] do
    {:noreply, socket}
  end

  defp send_message(socket, message) do
    user_id = socket.assigns.user_id
    character = socket.assigns.character

    # Extract and store projects from user message
    if user_id do
      GreenManTavern.MindsDB.MemoryExtractor.extract_and_store_projects(user_id, message)
    end

    # Add user message to UI
    user_message = %{
      id: System.unique_integer([:positive]),
      type: :user,
      content: message,
      timestamp: DateTime.utc_now()
    }

    new_messages = socket.assigns.chat_messages ++ [user_message]

    # Update UI with user message and loading state
    socket =
      socket
      |> assign(:chat_messages, new_messages)
      |> assign(:current_message, "")
      |> assign(:is_loading, true)

    # Store user message in conversation history
    if user_id do
      GreenManTavern.Conversations.create_conversation_entry(%{
        user_id: user_id,
        character_id: character.id,
        message_type: "user",
        content: message,
        timestamp: DateTime.utc_now()
      })
    end

    # Send to MindsDB for processing
    if user_id do
      IO.puts("🎯 [1/4] SENDING ASYNC MESSAGE TO SELF: '#{message}'")
      IO.puts("🎯 [2/4] Self PID: #{inspect(self())}")
      send(self(), {:process_with_mindsdb, user_id, character, message})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:process_with_mindsdb, user_id, character, message}, socket) do
    # Debug logging - handle_info called
    IO.puts("🎯 [3/4] RECEIVED ASYNC MESSAGE: '#{message}'")
    IO.puts("🎯 [4/4] Processing started for: '#{message}'")
    IO.puts("=== HANDLE INFO CALLED ===")
    IO.puts("Processing message: #{message}")

    # Debug logging
    IO.puts("=== PROCESSING MESSAGE ===")
    IO.puts("User: #{user_id}, Character: #{character.name}")
    IO.puts("Message: #{message}")

    # Build context for MindsDB query
    context = GreenManTavern.MindsDB.ContextBuilder.build_character_context(user_id, character.id)

    # Debug logging before MindsDB call
    IO.puts("=== CALLING MINDSDB ===")
    IO.puts("Agent: #{character.mindsdb_agent_name}")

    # Query MindsDB for character response
    result = GreenManTavern.MindsDB.Client.query_agent(character.mindsdb_agent_name, message, context)

    # Debug logging after MindsDB call
    IO.puts("=== MINDSDB RESPONSE ===")
    IO.puts("Result: #{inspect(result)}")

    case result do
      {:ok, response} ->

        character_response = %{
          id: System.unique_integer([:positive]),
          type: :character,
          content: response,
          timestamp: DateTime.utc_now()
        }

        new_messages = socket.assigns.chat_messages ++ [character_response]

        # Store character response in conversation history
        GreenManTavern.Conversations.create_conversation_entry(%{
          user_id: user_id,
          character_id: character.id,
          message_type: "character",
          content: response,
          timestamp: DateTime.utc_now()
        })

        # Update trust level based on interaction
        update_trust_level(user_id, character.id, message, response)

        {:noreply,
         socket
         |> assign(:chat_messages, new_messages)
         |> assign(:is_loading, false)}
    end
  end

  defp update_trust_level(_user_id, _character_id, _message, _response) do
    # TODO: Implement trust level updates
    :ok
  end
end
