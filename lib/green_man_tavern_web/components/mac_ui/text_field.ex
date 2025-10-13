defmodule GreenManTavernWeb.Components.MacUI.TextField do
  @moduledoc """
  MacTextField: Classic inset-bevel text input.
  """

  use Phoenix.Component

  @doc type: :component
  attr :name, :string, required: true
  attr :value, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :type, :string, default: "text"
  attr :disabled, :boolean, default: false
  attr :rest, :global

  def text_field(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      disabled={@disabled}
      class="mac-textfield"
      {@rest}
    />
    """
  end
end
