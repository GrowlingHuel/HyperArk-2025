defmodule GreenManTavernWeb.LivingWebLive do
  use GreenManTavernWeb, :live_view

  alias GreenManTavern.Systems

  # Import banner menu component
  import GreenManTavernWeb.BannerMenuComponent, only: [banner_menu: 1]

  @impl true
  def mount(_params, _session, socket) do
    # User is guaranteed to be authenticated due to router pipeline
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(:user_id, current_user.id)
      |> assign(:page_title, "Living Web")
      |> assign(:left_window_title, "Systems Library")
      |> assign(:right_window_title, "Living Web")
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hypercard-container">
      <!-- Banner Menu -->
      <div class="hypercard-banner">
        <div class="banner-title">Green Man Tavern</div>
        <div class="banner-menu">
          <.banner_menu current_character={assigns[:character]} current_user={assigns[:current_user]} />
        </div>
      </div>

      <!-- Dual Window Layout -->
      <div class="hypercard-windows">
        <!-- Left Window: Systems Library -->
        <div class="hypercard-window left-window">
          <div class="window-chrome">
            <div class="window-title">{@left_window_title}</div>
            <div class="window-controls">
              <div class="control-dot"></div>
              <div class="control-dot"></div>
              <div class="control-dot"></div>
            </div>
          </div>
          <div class="window-content">
            <div class="systems-library">
              <div class="library-header">
                <h3 class="library-title">Available Systems</h3>
                <div class="space-filter">
                  Space: <span class="space-type">{@user_space_type}</span>
                </div>
              </div>

              <div class="categories-list">
                <%= for {category, systems} <- @systems_by_category do %>
                  <div class="category-section">
                    <div class="category-header" phx-click="toggle_category" phx-value-category={category}>
                      <span class="category-icon">▼</span>
                      <span class="category-name">{Systems.get_category_info(category) |> elem(0)}</span>
                      <span class="category-count">({length(systems)})</span>
                    </div>
                    <div class="category-systems">
                      <%= for system <- systems do %>
                        <div class="system-item" phx-click="select_system" phx-value-system_id={system.id}>
                          <div class="system-icon" style={"background-color: #{system.color_scheme}"}>
                            <span class="icon-text">{system.icon_name}</span>
                          </div>
                          <div class="system-info">
                            <div class="system-name">{system.name}</div>
                            <div class="system-type">{system.system_type}</div>
                          </div>
                          <div class="system-actions">
                            <button
                              class="add-button"
                              phx-click="add_system"
                              phx-value-system_id={system.id}
                              phx-click-away="deselect_system"
                            >
                              +
                            </button>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Window: Living Web Canvas -->
        <div class="hypercard-window right-window">
          <div class="window-chrome">
            <div class="window-title">{@right_window_title}</div>
            <div class="window-controls">
              <div class="control-dot"></div>
              <div class="control-dot"></div>
              <div class="control-dot"></div>
            </div>
          </div>
          <div class="window-content">
            <div class="canvas-container">
              <svg
                viewBox="0 0 1200 800"
                class="living-web-canvas"
                phx-click="deselect_node"
              >
                <!-- Background grid and arrow markers -->
                <defs>
                  <pattern id="grid" width="50" height="50" patternUnits="userSpaceOnUse">
                    <path d="M 50 0 L 0 0 0 50" fill="none" stroke="#EEEEEE" stroke-width="1"/>
                  </pattern>
                  
                  <!-- Active connection arrow (green) -->
                  <marker
                    id="arrow-active"
                    markerWidth="10"
                    markerHeight="10"
                    refX="9"
                    refY="3"
                    orient="auto"
                    markerUnits="strokeWidth"
                  >
                    <path d="M0,0 L0,6 L9,3 z" fill="#22c55e" />
                  </marker>
                  
                  <!-- Potential connection arrow (orange) -->
                  <marker
                    id="arrow-potential"
                    markerWidth="10"
                    markerHeight="10"
                    refX="9"
                    refY="3"
                    orient="auto"
                    markerUnits="strokeWidth"
                  >
                    <path d="M0,0 L0,6 L9,3 z" fill="#f97316" />
                  </marker>
                </defs>
                <rect width="100%" height="100%" fill="url(#grid)" />

                <!-- CONNECTIONS FIRST (behind nodes) -->
                <%= for connection <- @user_connections do %>
                  <%= if from = find_system(@user_systems, connection.connection.from_system_id) do %>
                    <%= if to = find_system(@user_systems, connection.connection.to_system_id) do %>
                      <%= if rendered = render_connection(connection, from, to, @show_potential) do %>
                        {rendered}
                      <% end %>
                    <% end %>
                  <% end %>
                <% end %>

                <!-- User Systems (on top of connections) -->
                <%= if @user_systems == [] do %>
                  <text
                    x="600"
                    y="400"
                    text-anchor="middle"
                    font-family="Monaco, monospace"
                    font-size="16"
                    fill="#666666"
                  >
                    Drag systems from the library to start building your Living Web
                  </text>
                <% else %>
                  <%= for user_system <- @user_systems do %>
                    {render_node(user_system, @selected_node_id == user_system.system.id)}
                  <% end %>
                <% end %>

                <!-- Potential Connections (if enabled) -->
                <%= if @show_connections do %>
                  <%= for user_system <- @user_systems do %>
                    <%= for other_system <- @user_systems, other_system.id != user_system.id do %>
                      <line
                        x1={user_system.position_x}
                        y1={user_system.position_y}
                        x2={other_system.position_x}
                        y2={other_system.position_y}
                        stroke="#FFA500"
                        stroke-width="2"
                        stroke-dasharray="5,5"
                        opacity="0.6"
                        class="potential-connection"
                      />
                    <% end %>
                  <% end %>
                <% end %>
              </svg>

              <!-- Canvas Controls -->
              <div class="canvas-controls">
                <div class="controls-row">
                  <label class="control-checkbox">
                    <input
                      type="checkbox"
                      checked={@show_connections}
                      phx-click="toggle_connections"
                    />
                    <span>Show Potential Connections</span>
                  </label>
                  
                  <label class="control-checkbox">
                    <input
                      type="checkbox"
                      checked={@show_potential}
                      phx-click="toggle_potential"
                    />
                    <span>Show Potential Flows</span>
                  </label>
                </div>
              </div>

              <!-- Legend -->
              <div class="canvas-legend">
                <div class="legend-item">
                  <div class="legend-color active"></div>
                  <span>Active System</span>
                </div>
                <div class="legend-item">
                  <div class="legend-color potential"></div>
                  <span>Potential Connection</span>
                </div>
                <div class="legend-item">
                  <div class="legend-color process"></div>
                  <span>Process Node</span>
                </div>
              </div>
            </div>

            <!-- Selected System Details -->
            <%= if @selected_system do %>
              <div class="system-details">
                <div class="details-header">
                  <h4>{@selected_system.name}</h4>
                  <button class="close-button" phx-click="deselect_system">×</button>
                </div>
                <div class="details-content">
                  <div class="detail-row">
                    <span class="detail-label">Type:</span>
                    <span class="detail-value">{@selected_system.system_type}</span>
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">Category:</span>
                    <span class="detail-value">{@selected_system.category}</span>
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">Space Required:</span>
                    <span class="detail-value">{@selected_system.space_required}</span>
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">Skill Level:</span>
                    <span class="detail-value">{@selected_system.skill_level}</span>
                  </div>
                  <div class="detail-description">
                    <p>{@selected_system.description}</p>
                  </div>
                  <div class="detail-requirements">
                    <h5>Requirements:</h5>
                    <p>{@selected_system.requirements}</p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
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
end
