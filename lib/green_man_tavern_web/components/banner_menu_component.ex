defmodule GreenManTavernWeb.BannerMenuComponent do
  use GreenManTavernWeb, :html

  alias GreenManTavern.Characters

  attr :current_character, :map, default: nil

  def banner_menu(assigns) do
    characters = Characters.list_characters()

    assigns = assign(assigns, :characters, characters)

    ~H"""
    <div class="banner-menu">
      <span class="banner-logo">🍃 HyperArk</span>

      <div class="banner-menu-items">
        <.link navigate={~p"/"} class="banner-menu-item">Tavern</.link>

        <!-- Characters Dropdown -->
        <div class="dropdown-container">
          <button class="banner-menu-item dropdown-button">
            Characters ▾
          </button>

          <div class="dropdown-menu" id="characters-dropdown" style="display: none;">
            <%= for character <- @characters do %>
              <.link
                navigate={~p"/characters/#{Characters.name_to_slug(character.name)}"}
                class={[
                  "dropdown-item",
                  is_current_character?(character, @current_character) && "dropdown-item-current"
                ]}
              >
                <%= character.name %>
              </.link>
            <% end %>
          </div>
        </div>

        <.link navigate={~p"/database"} class="banner-menu-item">Database</.link>
        <.link navigate={~p"/garden"} class="banner-menu-item">Garden</.link>
        <.link navigate={~p"/living-web"} class="banner-menu-item">Living Web</.link>
      </div>
    </div>
    """
  end

  defp is_current_character?(character, current_character) do
    current_character && current_character.name == character.name
  end
end
