defmodule GreenManTavernWeb.BannerMenuComponent do
  use GreenManTavernWeb, :html

  alias GreenManTavern.Characters

  attr :current_character, :map, default: nil
  attr :current_user, :map, default: nil

  def banner_menu(assigns) do
    characters = Characters.list_characters()

    assigns = assign(assigns, :characters, characters)

    ~H"""
      <div class="banner-menu" style="height: 35px !important; background: #CCCCCC !important; border: 1px solid #000000 !important; display: flex !important; align-items: center !important; justify-content: flex-start; gap: 10px !important; padding: 0 12px !important; margin: 0 !important; line-height: 1 !important;">
        <!-- Logo/Brand -->
        <div class="banner-left" style="margin-right: 10px !important; display: flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
          <span class="banner-logo" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">🍃 HyperArk</span>
        </div>

        <!-- Navigation buttons - all in one container -->
        <a href="#" phx-click="navigate" phx-value-page="hyperark" class="banner-menu-item-invisible" style="margin-right: 10px !important; color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
          <span class="banner-icon-emoji" style="filter: grayscale(100%) !important; display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">🏰</span>
          <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Tavern</span>
        </a>

        <!-- Characters Dropdown -->
        <div style="position: relative; display: inline-block; margin-right: 10px !important;">
          <a
            href="#"
            id="characters-dropdown-btn"
            onclick="toggleCharactersDropdown(); event.preventDefault(); event.stopPropagation();"
            class="banner-menu-item-invisible"
            style="margin-right: 10px !important; color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;"
          >
            <span class="banner-icon-emoji" style="filter: grayscale(100%) !important; display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">🎭</span>
            <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Characters</span>
            <span style="font-size: 8px; line-height: 1; display: inline-block; margin: 0 !important; padding: 0 !important;">▾</span>
          </a>

          <div
            id="characters-dropdown-menu"
            style="display: none; position: absolute; top: calc(100% + 2px) !important; left: 0; background: #FFF !important; border: 2px solid #000 !important; min-width: 200px; z-index: 1000; box-shadow: 2px 2px 4px rgba(0,0,0,0.3);"
          >
            <%= for character <- @characters do %>
              <a
                href="#"
                phx-click="select_character"
                phx-value-character_slug={to_kebab_case(character.name)}
                style="display: block; padding: 8px 12px; font-family: Monaco, 'Courier New', monospace; font-size: 11px; color: #000; text-decoration: none; border-bottom: 1px solid #CCC; background: #FFF; cursor: pointer;"
                onmouseover="this.style.background='#EEE'"
                onmouseout="this.style.background='#FFF'"
              >
                {character.name}
              </a>
            <% end %>
          </div>
        </div>

        <a href="#" phx-click="navigate" phx-value-page="living_web" class="banner-menu-item-invisible" style="margin-right: 10px !important; color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
          <span class="banner-icon-emoji" style="filter: grayscale(100%) !important; display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">🌀</span>
          <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Living Web</span>
        </a>
        <a href="#" phx-click="navigate" phx-value-page="planting_guide" class="banner-menu-item-invisible" style="margin-right: 10px !important; color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
          <span class="banner-icon-emoji" style="filter: grayscale(100%) !important; display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">🍀</span>
          <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Planting Guide</span>
        </a>
        <a href="#" phx-click="navigate" phx-value-page="journal" class="banner-menu-item-invisible" style="margin-right: 10px !important; color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
          <span class="banner-icon-emoji" style="filter: grayscale(100%) !important; display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">✍️</span>
          <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Journal</span>
        </a>

        <!-- RIGHT: Authentication Section -->
        <div class="banner-auth-section" style="margin-left: auto !important; display: flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
        <%= if @current_user do %>
          <!-- User is logged in -->
          <span class="banner-user-info" style="display: inline-block !important; line-height: 1 !important; margin: 0 10px 0 0 !important; padding: 0 !important;">Welcome, {@current_user.email}</span>
          <.link href={~p"/logout"} method="delete" class="banner-menu-item-invisible" style="color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
            <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Logout</span>
          </.link>
        <% else %>
          <!-- User is not logged in -->
          <.link navigate={~p"/login"} class="banner-menu-item-invisible" style="color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important; margin-right: 10px !important;">
            <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Login</span>
          </.link>
          <.link navigate={~p"/register"} class="banner-menu-item-invisible" style="color: #000000 !important; text-decoration: none !important; display: inline-flex !important; align-items: center !important; padding: 0 !important; line-height: 1 !important; height: auto !important;">
            <span class="banner-text" style="display: inline-block !important; line-height: 1 !important; margin: 0 !important; padding: 0 !important;">Register</span>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  defp is_current_character?(character, current_character) do
    current_character && current_character.name == character.name
  end

  defp to_kebab_case(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
