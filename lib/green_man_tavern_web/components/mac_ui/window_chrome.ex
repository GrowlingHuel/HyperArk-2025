defmodule GreenManTavernWeb.Components.MacUI.WindowChrome do
  @moduledoc """
  Mac-style window chrome with title bar and optional close box.
  """

  use Phoenix.Component

  @doc type: :component
  attr :title, :string, required: true
  attr :closable, :boolean, default: false
  slot :inner_block, required: true

  def window_chrome(assigns) do
    ~H"""
    <div class="mac-window-chrome">
      <div class="mac-title-bar">
        <%= if @closable do %>
          <button type="button" class="mac-close-box" aria-label="Close">×</button>
        <% end %>
        <div class="mac-window-title truncate">{@title}</div>
      </div>
      <div class="mac-window-content mac-content-area">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
