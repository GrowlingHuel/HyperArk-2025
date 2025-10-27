defmodule GreenManTavernWeb.BannerMenuComponent do
  use GreenManTavernWeb, :html

  alias GreenManTavern.Characters

  attr :current_character, :map, default: nil
  attr :current_user, :map, default: nil

  def banner_menu(assigns) do
    characters = Characters.list_characters()

    assigns = assign(assigns, :characters, characters)

    ~H"""
    <div class="banner-menu">
      <!-- LEFT: Logo/Brand -->
      <div class="banner-left">
        <span class="banner-logo">🍃 HyperArk</span>
      </div>

    <!-- RIGHT: Navigation buttons -->
      <div class="banner-right">
        <.link navigate={~p"/"} class="banner-menu-item">Tavern</.link>

    <!-- Characters Selector -->
        <div class="character-selector">
          <select
            id="character-select"
            onchange="selectCharacterFromDropdown(this.value)"
            class="banner-menu-item"
            style="background: #CCC; border: 1px solid #000; padding: 4px 8px; font-size: 12px;"
          >
            <option value="">Characters</option>
            <%= for character <- @characters do %>
              <option
                value={character.id}
                selected={is_current_character?(character, @current_character)}
              >
                {character.name}
              </option>
            <% end %>
          </select>
        </div>

        <.link navigate={~p"/living-web"} class="banner-menu-item">Living Web</.link>

    <!-- Authentication Section -->
        <div class="banner-auth-section">
          <%= if @current_user do %>
            <!-- User is logged in -->
            <span class="banner-user-info">Welcome, {@current_user.email}</span>
            <.link href={~p"/logout"} method="delete" class="banner-menu-item">Logout</.link>
          <% else %>
            <!-- User is not logged in -->
            <.link navigate={~p"/login"} class="banner-menu-item">Login</.link>
            <.link navigate={~p"/register"} class="banner-menu-item">Register</.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp is_current_character?(character, current_character) do
    current_character && current_character.name == character.name
  end
end
