defmodule GreenManTavernWeb.Components.MacUI.Card do
  @moduledoc """
  MacCard: Simple content card with greyscale border and optional header.
  """

  use Phoenix.Component

  @doc type: :component
  attr :header, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["mac-card border border-[var(--medium-grey)] bg-[var(--pure-white)] p-3", @class]}>
      <%= if @header do %>
        <div class="font-bold text-[12px] border-b border-[var(--light-grey)] pb-1 mb-2">
          {@header}
        </div>
      <% end %>
      <div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
