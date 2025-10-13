defmodule GreenManTavernWeb.Components.MacUI.Button do
  @moduledoc """
  MacButton: Classic Mac OS bevel-style button.

  States: default (raised), hover (lighter), active (inset), disabled (flat grey).
  """

  use Phoenix.Component

  @doc type: :component
  attr :label, :string, required: true
  attr :disabled, :boolean, default: false
  attr :type, :string, default: "button"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(phx-click)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      class={["mac-button", @disabled && "mac-button-disabled", @class]}
      {@rest}
    >
      {@label}
    </button>
    """
  end
end
