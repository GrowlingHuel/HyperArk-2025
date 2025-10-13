defmodule GreenManTavernWeb.Components.MacUI.Window do
  @moduledoc """
  MacWindow: Classic Mac OS style window frame with a title bar and content area.

  Greyscale-only, sharp corners, hard shadows, no smooth animations.
  """

  use Phoenix.Component

  @doc type: :component
  attr :id, :string, default: nil, doc: "Optional DOM id for targeting"
  attr :title, :string, required: true, doc: "Window title text"
  attr :closable, :boolean, default: false, doc: "Show close button"
  slot :inner_block, required: true

  def window(assigns) do
    ~H"""
    <div id={@id} class="mac-window mac-shadow-hard border-2 border-[var(--medium-grey)] bg-[var(--pure-white)]">
      <div class="mac-window-titlebar flex items-center h-[24px] border-b border-[var(--medium-grey)] px-3 select-none">
        <%= if @closable do %>
          <button type="button" class="mac-titlebar-close mr-2 mac-bevel-raised h-4 w-4 text-[10px] leading-[10px] flex items-center justify-center font-bold" aria-label="Close">×</button>
        <% end %>
        <div class="truncate text-[12px] font-bold text-[var(--pure-black)]">
          {@title}
        </div>
      </div>
      <div class="p-3">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
