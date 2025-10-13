defmodule GreenManTavernWeb.Components.MacUI.Checkbox do
  @moduledoc """
  MacCheckbox: Classic square checkbox with X when checked.
  """

  use Phoenix.Component

  @doc type: :component
  attr :name, :string, required: true
  attr :checked, :boolean, default: false
  attr :label, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :rest, :global

  def checkbox(assigns) do
    ~H"""
    <label class="inline-flex items-center gap-2 text-[12px]">
      <input
        type="checkbox"
        name={@name}
        checked={@checked}
        disabled={@disabled}
        class="mac-checkbox"
        {@rest}
      />
      <%= if @label do %>
        <span>{@label}</span>
      <% end %>
    </label>
    """
  end
end
