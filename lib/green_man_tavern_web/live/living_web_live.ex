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
      |> assign(:show_connections, true)
      |> assign(:systems_by_category, [])
      |> assign(:user_systems, [])
      |> assign(:user_space_type, get_user_space_type(current_user))
      |> load_systems_data(current_user.id)

    {:ok, socket}
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
                phx-click="deselect_system"
              >
                <!-- Background grid -->
                <defs>
                  <pattern id="grid" width="50" height="50" patternUnits="userSpaceOnUse">
                    <path d="M 50 0 L 0 0 0 50" fill="none" stroke="#EEEEEE" stroke-width="1"/>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" fill="url(#grid)" />

                <!-- User Systems -->
                <%= for user_system <- @user_systems do %>
                  <g class="system-node" phx-click="select_system" phx-value-system_id={user_system.system.id}>
                    <circle 
                      cx={user_system.position_x} 
                      cy={user_system.position_y} 
                      r="20" 
                      fill={user_system.system.color_scheme}
                      stroke="#000000"
                      stroke-width="2"
                      class="system-circle"
                    />
                    <text 
                      x={user_system.position_x} 
                      y={user_system.position_y + 5} 
                      text-anchor="middle" 
                      font-family="Monaco, monospace" 
                      font-size="12"
                      fill="#000000"
                    >
                      {user_system.system.icon_name}
                    </text>
                  </g>
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
                <label class="control-checkbox">
                  <input 
                    type="checkbox" 
                    checked={@show_connections}
                    phx-click="toggle_connections"
                  />
                  Show Potential Connections
                </label>
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

  # Private functions

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

      socket
      |> assign(:systems_by_category, systems_by_category)
      |> assign(:user_systems, user_systems)
    rescue
      error ->
        socket
        |> put_flash(:error, "Failed to load systems data: #{inspect(error)}")
        |> assign(:systems_by_category, [])
        |> assign(:user_systems, [])
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
